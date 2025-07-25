#!/usr/bin/env python3
"""
P-System Membrane Namespace Client

Client library for membranes to interact with the distributed namespace registry.
Provides simple API for registration, discovery, and communication.
"""

import json
import time
import threading
import urllib.request
import urllib.parse
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import os

logger = logging.getLogger(__name__)

@dataclass
class MembraneEndpoint:
    """Membrane communication endpoint information"""
    id: str
    endpoint: str
    communication_mode: str
    metadata: Dict[str, Any]
    last_seen: float

class NamespaceClient:
    """Client for interacting with the namespace registry"""
    
    def __init__(self, membrane_id: str, registry_url: str = "http://localhost:8765",
                 auto_heartbeat: bool = True, heartbeat_interval: int = 25):
        self.membrane_id = membrane_id
        self.registry_url = registry_url.rstrip('/')
        self.auto_heartbeat = auto_heartbeat
        self.heartbeat_interval = heartbeat_interval
        
        # Heartbeat thread
        self.heartbeat_thread = None
        self.heartbeat_running = False
        
        # Cache for discovered membranes
        self.membrane_cache: Dict[str, MembraneEndpoint] = {}
        self.cache_ttl = 60  # Cache entries valid for 60 seconds
    
    def register(self, parent: Optional[str] = None, endpoint: str = None,
                communication_mode: str = "shared-volume", metadata: Dict[str, Any] = None) -> bool:
        """Register this membrane with the namespace registry"""
        try:
            # Auto-detect endpoint if not provided
            if endpoint is None:
                endpoint = self._auto_detect_endpoint(communication_mode)
            
            registration_data = {
                "id": self.membrane_id,
                "parent": parent,
                "endpoint": endpoint,
                "communication_mode": communication_mode,
                "health_check_url": None,  # Could add health check endpoint later
                "metadata": metadata or {},
                "registered_at": time.time(),
                "last_heartbeat": time.time()
            }
            
            response = self._post("/register", registration_data)
            success = response.get("success", False)
            
            if success:
                logger.info(f"Successfully registered membrane {self.membrane_id}")
                
                # Start auto-heartbeat if enabled
                if self.auto_heartbeat:
                    self._start_heartbeat()
            else:
                logger.error(f"Failed to register membrane {self.membrane_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Registration failed: {e}")
            return False
    
    def deregister(self) -> bool:
        """Deregister this membrane from the namespace registry"""
        try:
            # Stop heartbeat
            self._stop_heartbeat()
            
            response = self._post("/deregister", {"id": self.membrane_id})
            success = response.get("success", False)
            
            if success:
                logger.info(f"Successfully deregistered membrane {self.membrane_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Deregistration failed: {e}")
            return False
    
    def discover(self, target_membrane_id: str, use_cache: bool = True) -> Optional[MembraneEndpoint]:
        """Discover another membrane by ID"""
        try:
            # Check cache first if enabled
            if use_cache and target_membrane_id in self.membrane_cache:
                cached = self.membrane_cache[target_membrane_id]
                if time.time() - cached.last_seen < self.cache_ttl:
                    return cached
            
            # Query registry
            response = self._get(f"/discover/{target_membrane_id}")
            
            if response:
                endpoint = MembraneEndpoint(
                    id=response["id"],
                    endpoint=response["endpoint"],
                    communication_mode=response["communication_mode"],
                    metadata=response.get("metadata", {}),
                    last_seen=time.time()
                )
                
                # Update cache
                self.membrane_cache[target_membrane_id] = endpoint
                return endpoint
            
            return None
            
        except Exception as e:
            logger.error(f"Discovery failed for {target_membrane_id}: {e}")
            return None
    
    def list_membranes(self, parent: Optional[str] = None, 
                      communication_mode: Optional[str] = None) -> List[MembraneEndpoint]:
        """List membranes with optional filtering"""
        try:
            params = {}
            if parent is not None:
                params["parent"] = parent
            if communication_mode is not None:
                params["communication_mode"] = communication_mode
            
            query_string = urllib.parse.urlencode(params)
            url = f"/list?{query_string}" if query_string else "/list"
            
            response = self._get(url)
            
            endpoints = []
            for membrane_data in response or []:
                endpoint = MembraneEndpoint(
                    id=membrane_data["id"],
                    endpoint=membrane_data["endpoint"],
                    communication_mode=membrane_data["communication_mode"],
                    metadata=membrane_data.get("metadata", {}),
                    last_seen=time.time()
                )
                endpoints.append(endpoint)
                
                # Update cache
                self.membrane_cache[endpoint.id] = endpoint
            
            return endpoints
            
        except Exception as e:
            logger.error(f"List membranes failed: {e}")
            return []
    
    def send_message(self, target_membrane_id: str, message: Any, 
                    timeout: float = 30.0) -> bool:
        """Send a message to another membrane"""
        try:
            # Discover target membrane
            target = self.discover(target_membrane_id)
            if not target:
                logger.error(f"Cannot find target membrane {target_membrane_id}")
                return False
            
            # Route message based on communication mode
            if target.communication_mode == "shared-volume":
                return self._send_shared_volume(target, message)
            elif target.communication_mode == "network":
                return self._send_network(target, message, timeout)
            elif target.communication_mode == "ipc":
                return self._send_ipc(target, message, timeout)
            else:
                logger.error(f"Unsupported communication mode: {target.communication_mode}")
                return False
                
        except Exception as e:
            logger.error(f"Send message failed to {target_membrane_id}: {e}")
            return False
    
    def heartbeat(self) -> bool:
        """Send heartbeat to registry"""
        try:
            response = self._post("/heartbeat", {"id": self.membrane_id})
            return response.get("success", False)
        except Exception as e:
            logger.warning(f"Heartbeat failed: {e}")
            return False
    
    def _auto_detect_endpoint(self, communication_mode: str) -> str:
        """Auto-detect communication endpoint based on mode"""
        if communication_mode == "shared-volume":
            # Use membrane communication directory
            return f"/opt/membrane/communication/inbox/{self.membrane_id}"
        elif communication_mode == "network":
            # Use localhost with a port derived from membrane ID hash
            port = 9000 + (hash(self.membrane_id) % 1000)
            return f"http://localhost:{port}"
        elif communication_mode == "ipc":
            # Use Unix socket
            return f"/tmp/membrane_{self.membrane_id}.sock"
        else:
            return f"/opt/membrane/communication/inbox/{self.membrane_id}"
    
    def _send_shared_volume(self, target: MembraneEndpoint, message: Any) -> bool:
        """Send message via shared volume"""
        try:
            import os
            import json
            
            # Create target directory if it doesn't exist
            target_dir = target.endpoint
            os.makedirs(target_dir, exist_ok=True)
            
            # Write message to file
            message_file = f"{target_dir}/msg_{self.membrane_id}_{int(time.time() * 1000)}.json"
            message_data = {
                "sender": self.membrane_id,
                "timestamp": time.time(),
                "payload": message
            }
            
            with open(message_file, 'w') as f:
                json.dump(message_data, f)
            
            logger.debug(f"Sent message to {target.id} via shared volume: {message_file}")
            return True
            
        except Exception as e:
            logger.error(f"Shared volume send failed: {e}")
            return False
    
    def _send_network(self, target: MembraneEndpoint, message: Any, timeout: float) -> bool:
        """Send message via network"""
        try:
            message_data = {
                "sender": self.membrane_id,
                "timestamp": time.time(),
                "payload": message
            }
            
            data = json.dumps(message_data).encode()
            req = urllib.request.Request(
                f"{target.endpoint}/message",
                data=data,
                headers={"Content-Type": "application/json"}
            )
            
            with urllib.request.urlopen(req, timeout=timeout) as response:
                logger.debug(f"Sent message to {target.id} via network")
                return response.status == 200
                
        except Exception as e:
            logger.error(f"Network send failed: {e}")
            return False
    
    def _send_ipc(self, target: MembraneEndpoint, message: Any, timeout: float) -> bool:
        """Send message via IPC (placeholder - would need actual IPC implementation)"""
        logger.warning("IPC communication not yet implemented")
        return False
    
    def _start_heartbeat(self):
        """Start automatic heartbeat thread"""
        if not self.heartbeat_running:
            self.heartbeat_running = True
            self.heartbeat_thread = threading.Thread(target=self._heartbeat_worker, daemon=True)
            self.heartbeat_thread.start()
            logger.debug("Started heartbeat thread")
    
    def _stop_heartbeat(self):
        """Stop automatic heartbeat thread"""
        self.heartbeat_running = False
        if self.heartbeat_thread:
            self.heartbeat_thread.join(timeout=1.0)
    
    def _heartbeat_worker(self):
        """Background heartbeat worker"""
        while self.heartbeat_running:
            try:
                self.heartbeat()
                time.sleep(self.heartbeat_interval)
            except Exception as e:
                logger.warning(f"Heartbeat worker error: {e}")
                time.sleep(5)  # Shorter retry interval on error
    
    def _post(self, path: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Make HTTP POST request to registry"""
        url = f"{self.registry_url}{path}"
        payload = json.dumps(data).encode()
        
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"}
        )
        
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode())
    
    def _get(self, path: str) -> Any:
        """Make HTTP GET request to registry"""
        url = f"{self.registry_url}{path}"
        
        with urllib.request.urlopen(url, timeout=10) as response:
            return json.loads(response.read().decode())

def create_namespace_client(membrane_id: str = None, registry_url: str = None) -> NamespaceClient:
    """Factory function to create a namespace client with environment-based defaults"""
    
    if membrane_id is None:
        # Try to get membrane ID from environment or config
        membrane_id = os.environ.get("MEMBRANE_ID")
        if not membrane_id:
            # Try to read from config file
            try:
                import json
                with open("/opt/membrane/config/membrane.json", "r") as f:
                    config = json.load(f)
                    membrane_id = config.get("id", "unknown")
            except:
                membrane_id = "unknown"
    
    if registry_url is None:
        # Try to get registry URL from environment
        registry_url = os.environ.get("MEMBRANE_REGISTRY_URL", "http://localhost:8765")
    
    return NamespaceClient(membrane_id, registry_url)

if __name__ == "__main__":
    # Simple CLI for testing
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: namespace-client.py <command> [args...]")
        print("Commands: register, discover, list, send")
        sys.exit(1)
    
    command = sys.argv[1]
    client = create_namespace_client()
    
    if command == "register":
        parent = sys.argv[2] if len(sys.argv) > 2 else None
        success = client.register(parent=parent)
        print(f"Registration: {'success' if success else 'failed'}")
    
    elif command == "discover":
        if len(sys.argv) < 3:
            print("Usage: discover <membrane_id>")
            sys.exit(1)
        
        target_id = sys.argv[2]
        endpoint = client.discover(target_id)
        if endpoint:
            print(f"Found {target_id}: {endpoint.endpoint} ({endpoint.communication_mode})")
        else:
            print(f"Membrane {target_id} not found")
    
    elif command == "list":
        membranes = client.list_membranes()
        print(f"Found {len(membranes)} membranes:")
        for m in membranes:
            print(f"  {m.id}: {m.endpoint} ({m.communication_mode})")
    
    elif command == "send":
        if len(sys.argv) < 4:
            print("Usage: send <target_id> <message>")
            sys.exit(1)
        
        target_id = sys.argv[2]
        message = sys.argv[3]
        success = client.send_message(target_id, message)
        print(f"Send message: {'success' if success else 'failed'}")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)