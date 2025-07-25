#!/usr/bin/env python3
"""
P-System Membrane Distributed Namespace Registry

A lightweight distributed registry service that enables membranes to:
- Register themselves with the namespace
- Discover other membranes by ID
- Monitor membrane health and availability
- Maintain distributed state across multiple registry instances
"""

import json
import time
import threading
import socket
import http.server
import socketserver
import urllib.request
import urllib.parse
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from pathlib import Path
import sys
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class MembraneInfo:
    """Information about a registered membrane"""
    id: str
    parent: Optional[str]
    endpoint: str  # Communication endpoint (shared-volume path, network address, etc.)
    communication_mode: str
    health_check_url: Optional[str]
    metadata: Dict[str, Any]
    registered_at: float
    last_heartbeat: float
    status: str = "active"  # active, inactive, unhealthy

class NamespaceRegistry:
    """Distributed namespace registry for P-System membranes"""
    
    def __init__(self, registry_id: str, port: int = 8765, 
                 heartbeat_interval: int = 30, cleanup_interval: int = 60):
        self.registry_id = registry_id
        self.port = port
        self.heartbeat_interval = heartbeat_interval
        self.cleanup_interval = cleanup_interval
        
        # Registry state
        self.membranes: Dict[str, MembraneInfo] = {}
        self.peers: Dict[str, str] = {}  # registry_id -> endpoint
        self.lock = threading.RLock()
        
        # Background threads
        self.cleanup_thread = None
        self.running = False
        
        # Storage paths
        self.state_dir = Path("/opt/membrane/registry")
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.state_file = self.state_dir / "registry_state.json"
        
        # Load persisted state
        self._load_state()
    
    def start(self):
        """Start the registry service"""
        self.running = True
        
        # Start cleanup thread
        self.cleanup_thread = threading.Thread(target=self._cleanup_worker, daemon=True)
        self.cleanup_thread.start()
        
        # Start HTTP server
        server = HTTPRegistryServer(self, port=self.port)
        logger.info(f"Starting namespace registry {self.registry_id} on port {self.port}")
        server.serve_forever()
    
    def stop(self):
        """Stop the registry service"""
        self.running = False
        self._save_state()
    
    def register_membrane(self, membrane_info: MembraneInfo) -> bool:
        """Register a membrane in the namespace"""
        with self.lock:
            membrane_info.registered_at = time.time()
            membrane_info.last_heartbeat = time.time()
            self.membranes[membrane_info.id] = membrane_info
            
            logger.info(f"Registered membrane {membrane_info.id} with mode {membrane_info.communication_mode}")
            self._save_state()
            
            # Propagate to peer registries
            self._propagate_to_peers("register", asdict(membrane_info))
            return True
    
    def deregister_membrane(self, membrane_id: str) -> bool:
        """Deregister a membrane from the namespace"""
        with self.lock:
            if membrane_id in self.membranes:
                del self.membranes[membrane_id]
                logger.info(f"Deregistered membrane {membrane_id}")
                self._save_state()
                
                # Propagate to peer registries
                self._propagate_to_peers("deregister", {"id": membrane_id})
                return True
            return False
    
    def discover_membrane(self, membrane_id: str) -> Optional[MembraneInfo]:
        """Discover a membrane by ID"""
        with self.lock:
            return self.membranes.get(membrane_id)
    
    def list_membranes(self, parent: Optional[str] = None, 
                      communication_mode: Optional[str] = None) -> List[MembraneInfo]:
        """List membranes with optional filtering"""
        with self.lock:
            membranes = list(self.membranes.values())
            
            if parent is not None:
                membranes = [m for m in membranes if m.parent == parent]
            
            if communication_mode is not None:
                membranes = [m for m in membranes if m.communication_mode == communication_mode]
            
            return membranes
    
    def heartbeat(self, membrane_id: str) -> bool:
        """Update membrane heartbeat"""
        with self.lock:
            if membrane_id in self.membranes:
                self.membranes[membrane_id].last_heartbeat = time.time()
                self.membranes[membrane_id].status = "active"
                return True
            return False
    
    def add_peer_registry(self, peer_id: str, endpoint: str):
        """Add a peer registry for distributed operation"""
        with self.lock:
            self.peers[peer_id] = endpoint
            logger.info(f"Added peer registry {peer_id} at {endpoint}")
    
    def _cleanup_worker(self):
        """Background worker to cleanup stale membranes"""
        while self.running:
            try:
                time.sleep(self.cleanup_interval)
                current_time = time.time()
                
                with self.lock:
                    stale_membranes = []
                    for membrane_id, info in self.membranes.items():
                        # Consider membrane stale if no heartbeat for 2x the interval
                        if current_time - info.last_heartbeat > (self.heartbeat_interval * 2):
                            stale_membranes.append(membrane_id)
                            info.status = "unhealthy"
                    
                    # Remove very old stale membranes (no heartbeat for 5x interval)
                    for membrane_id, info in list(self.membranes.items()):
                        if current_time - info.last_heartbeat > (self.heartbeat_interval * 5):
                            logger.info(f"Removing stale membrane {membrane_id}")
                            del self.membranes[membrane_id]
                    
                    if stale_membranes:
                        logger.warning(f"Marked {len(stale_membranes)} membranes as unhealthy")
                        self._save_state()
                        
            except Exception as e:
                logger.error(f"Error in cleanup worker: {e}")
    
    def _propagate_to_peers(self, action: str, data: Dict[str, Any]):
        """Propagate changes to peer registries"""
        for peer_id, endpoint in self.peers.items():
            try:
                self._send_to_peer(endpoint, action, data)
            except Exception as e:
                logger.warning(f"Failed to propagate to peer {peer_id}: {e}")
    
    def _send_to_peer(self, endpoint: str, action: str, data: Dict[str, Any]):
        """Send data to a peer registry"""
        payload = json.dumps({"action": action, "data": data}).encode()
        req = urllib.request.Request(
            f"{endpoint}/peer-sync",
            data=payload,
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req, timeout=5)
    
    def _load_state(self):
        """Load registry state from disk"""
        try:
            if self.state_file.exists():
                with open(self.state_file, 'r') as f:
                    state = json.load(f)
                    
                # Reconstruct membrane objects
                for membrane_data in state.get("membranes", []):
                    membrane = MembraneInfo(**membrane_data)
                    self.membranes[membrane.id] = membrane
                
                self.peers = state.get("peers", {})
                logger.info(f"Loaded {len(self.membranes)} membranes from state")
        except Exception as e:
            logger.warning(f"Failed to load state: {e}")
    
    def _save_state(self):
        """Save registry state to disk"""
        try:
            state = {
                "membranes": [asdict(m) for m in self.membranes.values()],
                "peers": self.peers,
                "saved_at": time.time()
            }
            
            with open(self.state_file, 'w') as f:
                json.dump(state, f, indent=2)
        except Exception as e:
            logger.warning(f"Failed to save state: {e}")

class HTTPRegistryServer:
    """HTTP server for the namespace registry"""
    
    def __init__(self, registry: NamespaceRegistry, port: int):
        self.registry = registry
        self.port = port
    
    def serve_forever(self):
        """Start the HTTP server"""
        handler = self._create_handler()
        with socketserver.TCPServer(("", self.port), handler) as httpd:
            logger.info(f"Registry HTTP server listening on port {self.port}")
            httpd.serve_forever()
    
    def _create_handler(self):
        """Create HTTP request handler"""
        registry = self.registry
        
        class RegistryHandler(http.server.BaseHTTPRequestHandler):
            def do_POST(self):
                if self.path == "/register":
                    self._handle_register()
                elif self.path == "/deregister":
                    self._handle_deregister()
                elif self.path == "/heartbeat":
                    self._handle_heartbeat()
                elif self.path == "/peer-sync":
                    self._handle_peer_sync()
                else:
                    self._send_error(404, "Not Found")
            
            def do_GET(self):
                if self.path == "/status":
                    self._handle_status()
                elif self.path.startswith("/discover/"):
                    membrane_id = self.path.split("/")[-1]
                    self._handle_discover(membrane_id)
                elif self.path == "/list":
                    self._handle_list()
                else:
                    self._send_error(404, "Not Found")
            
            def _handle_register(self):
                try:
                    data = self._read_json()
                    membrane = MembraneInfo(**data)
                    success = registry.register_membrane(membrane)
                    self._send_json({"success": success})
                except Exception as e:
                    self._send_error(400, str(e))
            
            def _handle_deregister(self):
                try:
                    data = self._read_json()
                    success = registry.deregister_membrane(data["id"])
                    self._send_json({"success": success})
                except Exception as e:
                    self._send_error(400, str(e))
            
            def _handle_heartbeat(self):
                try:
                    data = self._read_json()
                    success = registry.heartbeat(data["id"])
                    self._send_json({"success": success})
                except Exception as e:
                    self._send_error(400, str(e))
            
            def _handle_discover(self, membrane_id):
                try:
                    membrane = registry.discover_membrane(membrane_id)
                    if membrane:
                        self._send_json(asdict(membrane))
                    else:
                        self._send_error(404, "Membrane not found")
                except Exception as e:
                    self._send_error(500, str(e))
            
            def _handle_list(self):
                try:
                    # Parse query parameters
                    query = urllib.parse.parse_qs(self.path.split("?", 1)[1] if "?" in self.path else "")
                    parent = query.get("parent", [None])[0]
                    comm_mode = query.get("communication_mode", [None])[0]
                    
                    membranes = registry.list_membranes(parent, comm_mode)
                    self._send_json([asdict(m) for m in membranes])
                except Exception as e:
                    self._send_error(500, str(e))
            
            def _handle_status(self):
                try:
                    status = {
                        "registry_id": registry.registry_id,
                        "membrane_count": len(registry.membranes),
                        "peer_count": len(registry.peers),
                        "uptime": time.time() - (registry.membranes.get(registry.registry_id, type('obj', (object,), {'registered_at': time.time()})).registered_at)
                    }
                    self._send_json(status)
                except Exception as e:
                    self._send_error(500, str(e))
            
            def _handle_peer_sync(self):
                try:
                    data = self._read_json()
                    action = data["action"]
                    payload = data["data"]
                    
                    if action == "register":
                        membrane = MembraneInfo(**payload)
                        registry.membranes[membrane.id] = membrane
                    elif action == "deregister":
                        membrane_id = payload["id"]
                        registry.membranes.pop(membrane_id, None)
                    
                    self._send_json({"success": True})
                except Exception as e:
                    self._send_error(400, str(e))
            
            def _read_json(self):
                content_length = int(self.headers.get('Content-Length', 0))
                data = self.rfile.read(content_length)
                return json.loads(data.decode())
            
            def _send_json(self, data):
                response = json.dumps(data).encode()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(response)))
                self.end_headers()
                self.wfile.write(response)
            
            def _send_error(self, code, message):
                self.send_response(code)
                self.send_header('Content-Type', 'text/plain')
                self.end_headers()
                self.wfile.write(message.encode())
            
            def log_message(self, format, *args):
                # Suppress default HTTP logs to avoid clutter
                pass
        
        return RegistryHandler

def main():
    """Main entry point for the registry service"""
    import argparse
    
    parser = argparse.ArgumentParser(description="P-System Membrane Namespace Registry")
    parser.add_argument("--registry-id", default="default", help="Registry instance ID")
    parser.add_argument("--port", type=int, default=8765, help="HTTP server port")
    parser.add_argument("--heartbeat-interval", type=int, default=30, help="Heartbeat interval in seconds")
    parser.add_argument("--cleanup-interval", type=int, default=60, help="Cleanup interval in seconds")
    
    args = parser.parse_args()
    
    registry = NamespaceRegistry(
        registry_id=args.registry_id,
        port=args.port,
        heartbeat_interval=args.heartbeat_interval,
        cleanup_interval=args.cleanup_interval
    )
    
    try:
        registry.start()
    except KeyboardInterrupt:
        logger.info("Shutting down registry...")
        registry.stop()

if __name__ == "__main__":
    main()