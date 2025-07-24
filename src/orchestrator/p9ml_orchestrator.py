#!/usr/bin/env python3
"""
P9ML Neural Membrane Orchestrator
Deploy and manage complex neural membrane hierarchies with cognitive architectures
"""

import json
import yaml
import os
import argparse
import sys
from typing import Dict, List, Optional, Tuple
import subprocess
import time

class P9MLMembraneOrchestrator:
    def __init__(self, orchestration_type: str = "docker-compose"):
        self.orchestration_type = orchestration_type
        self.output_dir = "/opt/orchestrator/generated"
        self.templates_dir = "/opt/orchestrator/templates"
        
        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)
        os.makedirs(self.templates_dir, exist_ok=True)
    
    def load_cognitive_architecture(self, config_file: str) -> Dict:
        """Load P9ML cognitive architecture configuration"""
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            print(f"Loaded cognitive architecture: {config.get('name', 'Unknown')}")
            return config
        except Exception as e:
            print(f"Error loading configuration: {e}")
            sys.exit(1)
    
    def generate_docker_compose(self, config: Dict) -> str:
        """Generate Docker Compose configuration for neural membrane hierarchy"""
        compose_config = {
            'version': '3.8',
            'services': {},
            'volumes': {
                'membrane-communication': None,
                'membrane-state': None,
                'neural-tensors': None,
                'namespace-registry': None
            },
            'networks': {
                'neural-membrane-net': {
                    'driver': 'bridge'
                }
            }
        }
        
        # Process each membrane in the cognitive architecture
        for membrane in config.get('membranes', []):
            service_name = f"membrane-{membrane['id']}"
            
            # Base service configuration
            service_config = {
                'build': {
                    'context': '.',
                    'dockerfile': 'Dockerfile.neural-membrane'
                },
                'environment': self._generate_membrane_environment(membrane, config),
                'volumes': [
                    'membrane-communication:/opt/membrane/communication',
                    'membrane-state:/opt/membrane/state',
                    'neural-tensors:/opt/membrane/p9ml/tensors',
                    'namespace-registry:/opt/membrane/namespace'
                ],
                'networks': ['neural-membrane-net'],
                'restart': 'unless-stopped'
            }
            
            # Add resource limits for neural processing
            if membrane.get('p9ml', {}).get('enabled', False):
                service_config['deploy'] = {
                    'resources': {
                        'limits': {
                            'memory': self._calculate_memory_limit(membrane),
                            'cpus': '2.0'
                        },
                        'reservations': {
                            'memory': '1G',
                            'cpus': '0.5'
                        }
                    }
                }
            
            # Add dependencies based on parent-child relationships
            if membrane.get('parent'):
                service_config['depends_on'] = [f"membrane-{membrane['parent']}"]
            
            # Add health checks for neural components
            if membrane.get('p9ml', {}).get('enabled', False):
                service_config['healthcheck'] = {
                    'test': ['CMD', 'membrane', 'neural', 'stats'],
                    'interval': '30s',
                    'timeout': '10s',
                    'retries': 3,
                    'start_period': '40s'
                }
            
            compose_config['services'][service_name] = service_config
        
        # Add visualization service if enabled
        if config.get('visualization', {}).get('enabled', False):
            compose_config['services']['neural-visualization'] = {
                'build': {
                    'context': '.',
                    'dockerfile': 'Dockerfile.visualization'
                },
                'ports': ['8080:8000'],
                'volumes': [
                    'membrane-state:/opt/membrane/state:ro',
                    'neural-tensors:/opt/membrane/p9ml/tensors:ro'
                ],
                'networks': ['neural-membrane-net'],
                'depends_on': list(compose_config['services'].keys())
            }
        
        return yaml.dump(compose_config, default_flow_style=False, sort_keys=False)
    
    def _generate_membrane_environment(self, membrane: Dict, global_config: Dict) -> List[str]:
        """Generate environment variables for a membrane container"""
        env_vars = [
            f"MEMBRANE_ID={membrane['id']}",
            f"PARENT_MEMBRANE={membrane.get('parent', '')}",
            f"ENABLE_SCHEME={str(membrane.get('enable_scheme', True)).lower()}",
            f"ENABLE_MONITORING={str(membrane.get('enable_monitoring', True)).lower()}",
            f"COMMUNICATION_MODE={membrane.get('communication_mode', 'tensor-exchange')}"
        ]
        
        # Add P9ML configuration
        p9ml_config = membrane.get('p9ml', {})
        if p9ml_config.get('enabled', False):
            env_vars.extend([
                f"ENABLE_P9ML=true",
                f"TENSOR_DIMENSIONS={p9ml_config.get('tensor_dimensions', 40)}",
                f"ENABLE_QUANTIZATION={str(p9ml_config.get('quantization_enabled', True)).lower()}",
                f"COGNITIVE_KERNEL={str(p9ml_config.get('cognitive_kernel', True)).lower()}",
                f"NAMESPACE_REGISTRY={str(p9ml_config.get('namespace_registry', False)).lower()}"
            ])
        else:
            env_vars.append("ENABLE_P9ML=false")
        
        # Add neural architecture information
        neural_arch = membrane.get('neural_architecture', {})
        if neural_arch:
            env_vars.extend([
                f"NEURAL_LAYERS={','.join(neural_arch.get('layers', []))}",
                f"ACTIVATION_FUNCTION={neural_arch.get('activation', 'tanh')}",
                f"SPECIALIZATION={neural_arch.get('specialization', 'general')}"
            ])
        
        return env_vars
    
    def _calculate_memory_limit(self, membrane: Dict) -> str:
        """Calculate memory limit based on tensor dimensions and neural architecture"""
        tensor_dims = membrane.get('p9ml', {}).get('tensor_dimensions', 40)
        base_memory = 1024  # Base 1GB
        
        # Scale memory with tensor dimensions
        tensor_memory = (tensor_dims ** 2) // 1000  # Rough estimation
        
        # Add memory for specific neural architectures
        specialization = membrane.get('neural_architecture', {}).get('specialization', 'general')
        if specialization in ['working_memory', 'episodic_memory']:
            memory_slots = membrane.get('neural_architecture', {}).get('memory_slots', 256)
            tensor_memory += memory_slots // 10
        
        total_memory = base_memory + tensor_memory
        return f"{total_memory}M"
    
    def generate_kubernetes_manifests(self, config: Dict) -> str:
        """Generate Kubernetes manifests for neural membrane deployment"""
        manifests = []
        
        # Namespace
        namespace = {
            'apiVersion': 'v1',
            'kind': 'Namespace',
            'metadata': {
                'name': 'neural-membrane-system',
                'labels': {
                    'p9ml.enabled': 'true',
                    'cognitive-architecture': config.get('name', 'unknown')
                }
            }
        }
        manifests.append(namespace)
        
        # ConfigMap for global P9ML configuration
        configmap = {
            'apiVersion': 'v1',
            'kind': 'ConfigMap',
            'metadata': {
                'name': 'p9ml-config',
                'namespace': 'neural-membrane-system'
            },
            'data': {
                'p9ml-config.json': json.dumps(config.get('p9ml_config', {})),
                'quantization-settings.json': json.dumps(config.get('quantization_settings', {})),
                'namespace-config.json': json.dumps(config.get('namespace_configuration', {}))
            }
        }
        manifests.append(configmap)
        
        # Persistent volumes for neural data
        for volume_name in ['neural-tensors', 'membrane-state', 'namespace-registry']:
            pv = {
                'apiVersion': 'v1',
                'kind': 'PersistentVolume',
                'metadata': {
                    'name': f'p9ml-{volume_name}',
                    'labels': {
                        'type': 'neural-storage'
                    }
                },
                'spec': {
                    'capacity': {'storage': '10Gi'},
                    'accessModes': ['ReadWriteMany'],
                    'persistentVolumeReclaimPolicy': 'Retain',
                    'hostPath': {'path': f'/opt/p9ml/{volume_name}'}
                }
            }
            manifests.append(pv)
        
        # Generate deployments for each membrane
        for membrane in config.get('membranes', []):
            deployment = self._generate_k8s_deployment(membrane, config)
            manifests.append(deployment)
            
            # Generate service for membranes that need external access
            if membrane.get('type') in ['neural_root', 'neural_hub']:
                service = self._generate_k8s_service(membrane)
                manifests.append(service)
        
        # Combine all manifests
        manifest_yaml = '---\n'.join([yaml.dump(manifest, default_flow_style=False) for manifest in manifests])
        return manifest_yaml
    
    def _generate_k8s_deployment(self, membrane: Dict, global_config: Dict) -> Dict:
        """Generate Kubernetes deployment for a membrane"""
        deployment = {
            'apiVersion': 'apps/v1',
            'kind': 'Deployment',
            'metadata': {
                'name': f"membrane-{membrane['id']}",
                'namespace': 'neural-membrane-system',
                'labels': {
                    'app': f"membrane-{membrane['id']}",
                    'membrane-type': membrane.get('type', 'neural_processor'),
                    'p9ml-enabled': str(membrane.get('p9ml', {}).get('enabled', False)).lower()
                }
            },
            'spec': {
                'replicas': 1,
                'selector': {
                    'matchLabels': {
                        'app': f"membrane-{membrane['id']}"
                    }
                },
                'template': {
                    'metadata': {
                        'labels': {
                            'app': f"membrane-{membrane['id']}",
                            'membrane-type': membrane.get('type', 'neural_processor')
                        }
                    },
                    'spec': {
                        'containers': [{
                            'name': 'neural-membrane',
                            'image': 'neural-membrane:latest',
                            'env': [{'name': k, 'value': v} for k, v in zip(
                                [env.split('=')[0] for env in self._generate_membrane_environment(membrane, global_config)],
                                [env.split('=')[1] for env in self._generate_membrane_environment(membrane, global_config)]
                            )],
                            'resources': {
                                'limits': {
                                    'memory': self._calculate_memory_limit(membrane),
                                    'cpu': '2000m'
                                },
                                'requests': {
                                    'memory': '1Gi',
                                    'cpu': '500m'
                                }
                            },
                            'volumeMounts': [
                                {
                                    'name': 'neural-tensors',
                                    'mountPath': '/opt/membrane/p9ml/tensors'
                                },
                                {
                                    'name': 'membrane-state',
                                    'mountPath': '/opt/membrane/state'
                                },
                                {
                                    'name': 'p9ml-config',
                                    'mountPath': '/opt/membrane/config/global'
                                }
                            ]
                        }],
                        'volumes': [
                            {
                                'name': 'neural-tensors',
                                'persistentVolumeClaim': {
                                    'claimName': 'neural-tensors-pvc'
                                }
                            },
                            {
                                'name': 'membrane-state',
                                'persistentVolumeClaim': {
                                    'claimName': 'membrane-state-pvc'
                                }
                            },
                            {
                                'name': 'p9ml-config',
                                'configMap': {
                                    'name': 'p9ml-config'
                                }
                            }
                        ]
                    }
                }
            }
        }
        
        return deployment
    
    def _generate_k8s_service(self, membrane: Dict) -> Dict:
        """Generate Kubernetes service for a membrane"""
        return {
            'apiVersion': 'v1',
            'kind': 'Service',
            'metadata': {
                'name': f"membrane-{membrane['id']}-service",
                'namespace': 'neural-membrane-system'
            },
            'spec': {
                'selector': {
                    'app': f"membrane-{membrane['id']}"
                },
                'ports': [
                    {'port': 8888, 'targetPort': 8888, 'name': 'namespace-registry'},
                    {'port': 8080, 'targetPort': 8080, 'name': 'visualization'}
                ]
            }
        }
    
    def deploy_architecture(self, config_file: str, output_file: str = None) -> bool:
        """Deploy the neural cognitive architecture"""
        config = self.load_cognitive_architecture(config_file)
        
        if self.orchestration_type == "docker-compose":
            compose_yaml = self.generate_docker_compose(config)
            output_path = output_file or os.path.join(self.output_dir, "neural-cognitive-architecture.yml")
            
            with open(output_path, 'w') as f:
                f.write(compose_yaml)
            
            print(f"Generated Docker Compose configuration: {output_path}")
            
            # Deploy using docker-compose
            try:
                subprocess.run(['docker-compose', '-f', output_path, 'up', '-d'], check=True)
                print("✓ Neural cognitive architecture deployed successfully")
                return True
            except subprocess.CalledProcessError as e:
                print(f"✗ Deployment failed: {e}")
                return False
                
        elif self.orchestration_type == "kubernetes":
            k8s_yaml = self.generate_kubernetes_manifests(config)
            output_path = output_file or os.path.join(self.output_dir, "neural-cognitive-k8s.yml")
            
            with open(output_path, 'w') as f:
                f.write(k8s_yaml)
            
            print(f"Generated Kubernetes manifests: {output_path}")
            
            # Deploy using kubectl
            try:
                subprocess.run(['kubectl', 'apply', '-f', output_path], check=True)
                print("✓ Neural cognitive architecture deployed to Kubernetes")
                return True
            except subprocess.CalledProcessError as e:
                print(f"✗ Kubernetes deployment failed: {e}")
                return False
        
        return False
    
    def status(self) -> None:
        """Check status of deployed neural membranes"""
        if self.orchestration_type == "docker-compose":
            try:
                result = subprocess.run(['docker-compose', 'ps'], capture_output=True, text=True)
                print("Neural Membrane System Status (Docker Compose):")
                print(result.stdout)
            except subprocess.CalledProcessError as e:
                print(f"Error checking status: {e}")
        
        elif self.orchestration_type == "kubernetes":
            try:
                result = subprocess.run(['kubectl', 'get', 'pods', '-n', 'neural-membrane-system'], 
                                      capture_output=True, text=True)
                print("Neural Membrane System Status (Kubernetes):")
                print(result.stdout)
            except subprocess.CalledProcessError as e:
                print(f"Error checking Kubernetes status: {e}")
    
    def teardown(self, config_file: str = None) -> bool:
        """Teardown deployed neural membrane system"""
        if self.orchestration_type == "docker-compose":
            compose_file = os.path.join(self.output_dir, "neural-cognitive-architecture.yml")
            if os.path.exists(compose_file):
                try:
                    subprocess.run(['docker-compose', '-f', compose_file, 'down'], check=True)
                    print("✓ Neural cognitive architecture stopped")
                    return True
                except subprocess.CalledProcessError as e:
                    print(f"✗ Teardown failed: {e}")
                    return False
        
        elif self.orchestration_type == "kubernetes":
            try:
                subprocess.run(['kubectl', 'delete', 'namespace', 'neural-membrane-system'], check=True)
                print("✓ Neural cognitive architecture removed from Kubernetes")
                return True
            except subprocess.CalledProcessError as e:
                print(f"✗ Kubernetes teardown failed: {e}")
                return False
        
        return False

def main():
    parser = argparse.ArgumentParser(description='P9ML Neural Membrane Orchestrator')
    parser.add_argument('command', choices=['deploy', 'status', 'teardown', 'generate'],
                       help='Command to execute')
    parser.add_argument('config_file', nargs='?', 
                       help='Cognitive architecture configuration file')
    parser.add_argument('--type', choices=['docker-compose', 'kubernetes'], 
                       default='docker-compose',
                       help='Orchestration type')
    parser.add_argument('--output', help='Output file path')
    
    args = parser.parse_args()
    
    orchestrator = P9MLMembraneOrchestrator(args.type)
    
    if args.command == 'deploy':
        if not args.config_file:
            print("Error: Configuration file required for deployment")
            sys.exit(1)
        orchestrator.deploy_architecture(args.config_file, args.output)
    
    elif args.command == 'generate':
        if not args.config_file:
            print("Error: Configuration file required for generation")
            sys.exit(1)
        config = orchestrator.load_cognitive_architecture(args.config_file)
        
        if args.type == 'docker-compose':
            output = orchestrator.generate_docker_compose(config)
        else:
            output = orchestrator.generate_kubernetes_manifests(config)
        
        if args.output:
            with open(args.output, 'w') as f:
                f.write(output)
            print(f"Generated configuration: {args.output}")
        else:
            print(output)
    
    elif args.command == 'status':
        orchestrator.status()
    
    elif args.command == 'teardown':
        orchestrator.teardown(args.config_file)

if __name__ == '__main__':
    main()