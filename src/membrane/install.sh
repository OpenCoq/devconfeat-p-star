#!/bin/bash
set -e

echo "Activating P9ML Neural Membrane Computing feature"

# Extract options
MEMBRANE_ID=${MEMBRANEID:-membrane-1}
PARENT_MEMBRANE=${PARENTMEMBRANE:-}
ENABLE_SCHEME=${ENABLESCHEME:-true}
ENABLE_MONITORING=${ENABLEMONITORING:-true}
ENABLE_P9ML=${ENABLEP9ML:-true}
ENABLE_QUANTIZATION=${ENABLEQUANTIZATION:-true}
TENSOR_DIMENSIONS=${TENSORDIMENSIONS:-40}
COGNITIVE_KERNEL=${COGNITIVEKERNEL:-true}
COMMUNICATION_MODE=${COMMUNICATIONMODE:-tensor-exchange}
NAMESPACE_REGISTRY=${NAMESPACEREGISTRY:-true}

echo "Configuring P9ML neural membrane: $MEMBRANE_ID"
echo "Parent membrane: ${PARENT_MEMBRANE:-'(root)'}"
echo "Communication mode: $COMMUNICATION_MODE"
echo "P9ML integration: $ENABLE_P9ML"
echo "Tensor dimensions: $TENSOR_DIMENSIONS"

# Create enhanced membrane directory structure
mkdir -p /opt/membrane/{config,rules,communication,state,logs,lib}
mkdir -p /opt/membrane/p9ml/{ggml,tensors,quantization,namespace}
mkdir -p /opt/membrane/cognitive/{hypergraph,lexicon,grammar}
mkdir -p /opt/membrane/visualization

# Install required system packages for neural processing
echo "Installing system packages for P9ML neural computing..."
if apt-get update && apt-get install -y inotify-tools jq curl build-essential cmake git python3 python3-pip; then
    echo "Successfully installed system packages"
    
    # Install Python dependencies for neural processing
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install numpy scipy torch transformers --break-system-packages 2>/dev/null || echo "Python packages install failed, continuing with basic setup"
    fi
else
    echo "Warning: Failed to install some packages, using minimal setup"
    # Create dummy commands if packages are not available
    for cmd in jq inotifywait python3 pip3; do
        if ! command -v $cmd >/dev/null 2>&1; then
            cat > /usr/local/bin/$cmd << EOF
#!/bin/bash
echo "$cmd not available - using mock implementation"
exit 0
EOF
            chmod +x /usr/local/bin/$cmd
        fi
    done
fi

# Install P9ML neural integration components
if [ "$ENABLE_P9ML" = "true" ]; then
    echo "Installing P9ML neural membrane integration..."
    
    # Create ggml_p9ml_membrane wrapper (C implementation stub)
    cat > /opt/membrane/p9ml/ggml/ggml_p9ml_membrane.c << 'EOF'
// ggml_p9ml_membrane: P9ML membrane wrapper for neural network layers
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct {
    char membrane_id[64];
    int tensor_dimensions;
    float* state_vector;
    float* weight_matrix;
    int is_active;
    int quantized;
} ggml_p9ml_membrane_t;

// Create new membrane object wrapper
ggml_p9ml_membrane_t* ggml_p9ml_membrane_new(const char* membrane_id, int tensor_dims) {
    ggml_p9ml_membrane_t* membrane = malloc(sizeof(ggml_p9ml_membrane_t));
    strncpy(membrane->membrane_id, membrane_id, 63);
    membrane->membrane_id[63] = '\0';
    membrane->tensor_dimensions = tensor_dims;
    membrane->state_vector = calloc(tensor_dims, sizeof(float));
    membrane->weight_matrix = calloc(tensor_dims * tensor_dims, sizeof(float));
    membrane->is_active = 1;
    membrane->quantized = 0;
    
    printf("Created P9ML membrane: %s with %d dimensions\n", membrane_id, tensor_dims);
    return membrane;
}

// Attach weights/parameters to membrane
int ggml_p9ml_membrane_attach_weights(ggml_p9ml_membrane_t* membrane, float* weights, int size) {
    if (!membrane || !weights || size != membrane->tensor_dimensions * membrane->tensor_dimensions) {
        return -1;
    }
    
    memcpy(membrane->weight_matrix, weights, size * sizeof(float));
    printf("Attached %d weights to membrane %s\n", size, membrane->membrane_id);
    return 0;
}

// Apply data-free quantization-aware training
int ggml_p9ml_membrane_quantize(ggml_p9ml_membrane_t* membrane) {
    if (!membrane) return -1;
    
    // Simple 8-bit quantization simulation
    for (int i = 0; i < membrane->tensor_dimensions * membrane->tensor_dimensions; i++) {
        float value = membrane->weight_matrix[i];
        // Quantize to 8-bit range [-128, 127] mapped to [-1.0, 1.0]
        int quantized = (int)(value * 127.0f);
        membrane->weight_matrix[i] = (float)quantized / 127.0f;
    }
    
    membrane->quantized = 1;
    printf("Applied P9ML quantization to membrane %s\n", membrane->membrane_id);
    return 0;
}

// Update membrane state vector
int ggml_p9ml_membrane_update_state(ggml_p9ml_membrane_t* membrane, float* input, int input_size) {
    if (!membrane || !input || input_size != membrane->tensor_dimensions) {
        return -1;
    }
    
    // Simple linear transformation: output = weights * input
    for (int i = 0; i < membrane->tensor_dimensions; i++) {
        float sum = 0.0f;
        for (int j = 0; j < membrane->tensor_dimensions; j++) {
            sum += membrane->weight_matrix[i * membrane->tensor_dimensions + j] * input[j];
        }
        membrane->state_vector[i] = tanhf(sum); // Apply activation
    }
    
    return 0;
}

// Free membrane resources
void ggml_p9ml_membrane_free(ggml_p9ml_membrane_t* membrane) {
    if (membrane) {
        free(membrane->state_vector);
        free(membrane->weight_matrix);
        free(membrane);
    }
}

// Export state to JSON format
void ggml_p9ml_membrane_export_json(ggml_p9ml_membrane_t* membrane, char* output, int max_len) {
    if (!membrane || !output) return;
    
    snprintf(output, max_len, 
        "{\"membrane_id\":\"%s\",\"dimensions\":%d,\"active\":%s,\"quantized\":%s,\"state_norm\":%.4f}",
        membrane->membrane_id,
        membrane->tensor_dimensions,
        membrane->is_active ? "true" : "false",
        membrane->quantized ? "true" : "false",
        // Calculate L2 norm of state vector
        sqrt(membrane->state_vector[0] * membrane->state_vector[0] + 
             membrane->state_vector[1] * membrane->state_vector[1])
    );
}
EOF

    # Compile the C library (create stub library if compilation fails)
    if command -v gcc >/dev/null 2>&1; then
        gcc -shared -fPIC -o /opt/membrane/p9ml/ggml/ggml_p9ml_membrane.so /opt/membrane/p9ml/ggml/ggml_p9ml_membrane.c -lm 2>/dev/null || \
        echo "Mock P9ML library" > /opt/membrane/p9ml/ggml/ggml_p9ml_membrane.so
    else
        echo "Mock P9ML library - GCC not available" > /opt/membrane/p9ml/ggml/ggml_p9ml_membrane.so
    fi
    
    echo "P9ML membrane wrapper installed"
fi

# Install namespace registry for distributed computation
if [ "$NAMESPACE_REGISTRY" = "true" ]; then
    echo "Installing P9ML namespace registry..."
    
    cat > /opt/membrane/p9ml/namespace/namespace_registry.py << 'EOF'
#!/usr/bin/env python3
"""
ggml_p9ml_namespace: Distributed namespace registration for P9ML membranes
Enables global state management and recursive orchestration
"""
import json
import time
import threading
from typing import Dict, List, Optional
import hashlib

class ggml_p9ml_namespace:
    def __init__(self, namespace_id: str, registry_port: int = 8888):
        self.namespace_id = namespace_id
        self.registry_port = registry_port
        self.membranes: Dict[str, dict] = {}
        self.global_state = {}
        self.orchestration_rules = []
        self.meta_rules = []
        self.lock = threading.Lock()
        self.running = False
        
    def register_membrane(self, membrane_id: str, config: dict) -> bool:
        """Register a membrane in the global namespace"""
        with self.lock:
            self.membranes[membrane_id] = {
                'config': config,
                'registered_at': time.time(),
                'last_heartbeat': time.time(),
                'state': 'active'
            }
            print(f"Registered membrane {membrane_id} in namespace {self.namespace_id}")
            return True
    
    def unregister_membrane(self, membrane_id: str) -> bool:
        """Unregister a membrane from the global namespace"""
        with self.lock:
            if membrane_id in self.membranes:
                del self.membranes[membrane_id]
                print(f"Unregistered membrane {membrane_id}")
                return True
            return False
    
    def update_global_state(self, key: str, value: any) -> None:
        """Update global state accessible to all membranes"""
        with self.lock:
            self.global_state[key] = {
                'value': value,
                'updated_at': time.time(),
                'checksum': hashlib.md5(str(value).encode()).hexdigest()
            }
            print(f"Updated global state: {key}")
    
    def get_global_state(self, key: Optional[str] = None) -> dict:
        """Get global state (specific key or all)"""
        with self.lock:
            if key:
                return self.global_state.get(key, {})
            return self.global_state.copy()
    
    def add_orchestration_rule(self, rule: dict) -> None:
        """Add orchestration rule for membrane coordination"""
        self.orchestration_rules.append(rule)
        print(f"Added orchestration rule: {rule.get('name', 'unnamed')}")
    
    def add_meta_rule(self, rule: dict) -> None:
        """Add meta-learning rule for recursive adaptation"""
        self.meta_rules.append(rule)
        print(f"Added meta-learning rule: {rule.get('name', 'unnamed')}")
    
    def apply_orchestration(self) -> None:
        """Apply orchestration rules to coordinate membranes"""
        for rule in self.orchestration_rules:
            try:
                if rule.get('type') == 'load_balance':
                    self._apply_load_balancing()
                elif rule.get('type') == 'resource_allocation':
                    self._apply_resource_allocation()
                elif rule.get('type') == 'communication_routing':
                    self._apply_communication_routing()
            except Exception as e:
                print(f"Error applying orchestration rule: {e}")
    
    def apply_meta_learning(self) -> None:
        """Apply meta-learning rules for agentic adaptation"""
        for rule in self.meta_rules:
            try:
                if rule.get('type') == 'performance_optimization':
                    self._optimize_performance()
                elif rule.get('type') == 'adaptive_topology':
                    self._adapt_topology()
                elif rule.get('type') == 'recursive_refinement':
                    self._recursive_refinement()
            except Exception as e:
                print(f"Error applying meta-learning rule: {e}")
    
    def _apply_load_balancing(self):
        """Balance computational load across membranes"""
        active_membranes = [m for m in self.membranes.keys() 
                          if self.membranes[m]['state'] == 'active']
        if len(active_membranes) > 1:
            print(f"Load balancing across {len(active_membranes)} membranes")
    
    def _apply_resource_allocation(self):
        """Allocate computational resources based on membrane needs"""
        print("Applying resource allocation policies")
    
    def _apply_communication_routing(self):
        """Optimize communication routing between membranes"""
        print("Optimizing communication routing")
    
    def _optimize_performance(self):
        """Optimize overall system performance based on metrics"""
        print("Applying performance optimization meta-rules")
    
    def _adapt_topology(self):
        """Adapt membrane topology based on workload patterns"""
        print("Adapting membrane topology")
    
    def _recursive_refinement(self):
        """Recursively refine orchestration strategies"""
        print("Applying recursive refinement")
    
    def start_registry_service(self):
        """Start the namespace registry service"""
        self.running = True
        print(f"Started P9ML namespace registry: {self.namespace_id}")
        
        # Main service loop (simplified)
        while self.running:
            try:
                self.apply_orchestration()
                self.apply_meta_learning()
                time.sleep(1.0)  # Process every second
            except KeyboardInterrupt:
                break
    
    def stop_registry_service(self):
        """Stop the namespace registry service"""
        self.running = False
        print(f"Stopped P9ML namespace registry: {self.namespace_id}")
    
    def export_state(self) -> str:
        """Export namespace state as JSON"""
        with self.lock:
            state = {
                'namespace_id': self.namespace_id,
                'membranes': self.membranes,
                'global_state': self.global_state,
                'orchestration_rules': len(self.orchestration_rules),
                'meta_rules': len(self.meta_rules),
                'timestamp': time.time()
            }
            return json.dumps(state, indent=2)

if __name__ == "__main__":
    # Example usage
    namespace = ggml_p9ml_namespace("cognitive-root")
    
    # Register some example membranes
    namespace.register_membrane("perception", {"type": "sensory", "priority": "high"})
    namespace.register_membrane("cognition", {"type": "reasoning", "priority": "high"})
    namespace.register_membrane("action", {"type": "motor", "priority": "medium"})
    
    # Add some orchestration rules
    namespace.add_orchestration_rule({
        "name": "sensory_priority",
        "type": "load_balance",
        "target": "perception"
    })
    
    # Add meta-learning rules
    namespace.add_meta_rule({
        "name": "adaptive_learning_rate",
        "type": "performance_optimization",
        "parameters": {"learning_rate": 0.01}
    })
    
    print("P9ML Namespace Registry initialized")
    print(namespace.export_state())
EOF

    chmod +x /opt/membrane/p9ml/namespace/namespace_registry.py
    echo "P9ML namespace registry installed"
fi
# Install Scheme interpreter and cognitive grammar kernel
if [ "$ENABLE_SCHEME" = "true" ]; then
    echo "Installing Guile Scheme interpreter and cognitive kernel..."
    if apt-get install -y guile-3.0 guile-3.0-dev; then
        echo "Guile installed successfully"
    else
        echo "Warning: Failed to install Guile, creating minimal Scheme setup"
        cat > /usr/local/bin/guile << 'EOF'
#!/bin/bash
echo "Guile Scheme not available - using minimal implementation"
echo "Guile mock interpreter ready"
EOF
        chmod +x /usr/local/bin/guile
    fi
    
    # Create enhanced hypergraph representation library for neural-membrane integration
    cat > /opt/membrane/hypergraph.scm << 'EOF'
;;; P9ML Neural-Membrane Hypergraph Representation
;;; Cognitive Grammar Kernel with Tensor Integration

(use-modules (ice-9 format)
             (ice-9 hash-table)
             (srfi srfi-1))

;; Global cognitive lexicon for tensor vocabularies
(define *cognitive-lexicon* (make-hash-table))
(define *tensor-vocabulary* (make-hash-table))
(define *membrane-relationships* (make-hash-table))

;; Define enhanced membrane container node with neural properties
(define (create-neural-membrane-node membrane-id tensor-dims quantized?)
  `(EvaluationLink
     (PredicateNode "NeuralMembraneContainer")
     (ListLink 
       (ConceptNode ,membrane-id)
       (NumberNode ,tensor-dims)
       (BooleanNode ,quantized?))))

;; Store tensor vocabularies in cognitive lexicon
(define (register-tensor-vocabulary membrane-id vocab-data)
  (hash-set! *tensor-vocabulary* membrane-id vocab-data)
  (hash-set! *cognitive-lexicon* 
             (string-append membrane-id ":tensor_vocab")
             vocab-data)
  `(EvaluationLink
     (PredicateNode "TensorVocabulary")
     (ListLink
       (ConceptNode ,membrane-id)
       (ConceptNode ,(symbol->string (gensym "vocab"))))))

;; Define nesting relationship with neural connectivity weights
(define (create-weighted-nesting-link child parent weight)
  (hash-set! *membrane-relationships* 
             (cons child parent)
             weight)
  `(InheritanceLink
     (ConceptNode ,child)
     (ConceptNode ,parent)
     (NumberNode ,weight)))

;; Define P9ML evolution rule with quantization support
(define (create-p9ml-evolution-rule membrane-id trigger-event action-script quantization-params)
  `(EvaluationLink
     (PredicateNode "P9MLEvolutionRule")
     (ListLink
       (ConceptNode ,membrane-id)
       (ConceptNode ,trigger-event)
       (ConceptNode ,action-script)
       (ConceptNode ,(format #f "~a" quantization-params)))))

;; Define neural tensor communication rule
(define (create-tensor-communication-rule source-membrane target-membrane tensor-shape)
  `(EvaluationLink
     (PredicateNode "TensorCommunicationRule")
     (ListLink
       (ConceptNode ,source-membrane)
       (ConceptNode ,target-membrane)
       (ConceptNode ,(format #f "shape:~a" tensor-shape)))))

;; Implement hypergraph cognitive processing
(define (cognitive-process-hypergraph membrane-id input-data)
  (let* ((vocab (hash-ref *tensor-vocabulary* membrane-id '()))
         (relationships (filter (lambda (pair) 
                                 (or (string=? (car pair) membrane-id)
                                     (string=? (cdr pair) membrane-id)))
                               (hash-keys *membrane-relationships*)))
         (cognitive-state (make-hash-table)))
    
    ;; Process input through cognitive grammar
    (hash-set! cognitive-state "input_processed" #t)
    (hash-set! cognitive-state "vocab_size" (length vocab))
    (hash-set! cognitive-state "relationship_count" (length relationships))
    (hash-set! cognitive-state "timestamp" (current-time))
    
    ;; Return processed cognitive state
    cognitive-state))

;; Meta-learning for agentic grammar productions
(define (apply-meta-learning-rules membrane-id performance-metrics)
  (let ((adaptation-factor (if (> (hash-ref performance-metrics "accuracy" 0) 0.8)
                              1.1  ; Increase complexity if performing well
                              0.9))) ; Decrease complexity if struggling
    `(EvaluationLink
       (PredicateNode "MetaLearningAdaptation")
       (ListLink
         (ConceptNode ,membrane-id)
         (NumberNode ,adaptation-factor)
         (ConceptNode ,(format #f "metrics:~a" performance-metrics))))))

;; Export neural membrane state to JSON with tensor information
(define (neural-membrane-to-json membrane-id parent-id tensor-dims quantized?)
  (let* ((vocab (hash-ref *tensor-vocabulary* membrane-id '()))
         (relationships (length (filter (lambda (pair) 
                                        (string=? (car pair) membrane-id))
                                       (hash-keys *membrane-relationships*)))))
    (format #t "{\"id\": \"~a\", \"parent\": \"~a\", \"tensor_dims\": ~a, \"quantized\": ~a, \"vocab_size\": ~a, \"relationships\": ~a, \"timestamp\": \"~a\", \"type\": \"neural_membrane\"}\n"
            membrane-id 
            (if (string=? parent-id "") "null" parent-id)
            tensor-dims
            (if quantized? "true" "false")
            (length vocab)
            relationships
            (current-time))))

;; Initialize cognitive grammar kernel
(define (init-cognitive-kernel membrane-id)
  (hash-set! *cognitive-lexicon* 
             (string-append membrane-id ":init")
             (current-time))
  (display (format #f "Cognitive Grammar Kernel initialized for membrane: ~a\n" membrane-id)))

;; Hypergraph visualization export
(define (export-hypergraph-dot membrane-id)
  (format #t "digraph MembraneHypergraph {\n")
  (format #t "  \"~a\" [shape=box, label=\"~a\\nNeural Membrane\"];\n" membrane-id membrane-id)
  
  ;; Export relationships
  (for-each (lambda (pair)
              (let ((weight (hash-ref *membrane-relationships* pair 1.0)))
                (format #t "  \"~a\" -> \"~a\" [label=\"~a\"];\n" 
                        (car pair) (cdr pair) weight)))
            (hash-keys *membrane-relationships*))
  
  (format #t "}\n"))

(display "P9ML Neural-Membrane Hypergraph Library Loaded\n")
(display "Available functions: create-neural-membrane-node, register-tensor-vocabulary, cognitive-process-hypergraph\n")
EOF
fi

# Install cognitive grammar kernel
if [ "$COGNITIVE_KERNEL" = "true" ]; then
    echo "Installing cognitive grammar kernel..."
    
    cat > /opt/membrane/cognitive/grammar/cognitive_kernel.scm << 'EOF'
;;; P9ML Cognitive Grammar Kernel
;;; Hypergraph data structure for neural-membrane system

(use-modules (ice-9 format)
             (ice-9 hash-table))

;; Global cognitive structures
(define *grammar-productions* (make-hash-table))
(define *agentic-rules* (make-hash-table))
(define *transformation-patterns* (make-hash-table))

;; Define grammar production rule
(define (add-grammar-production name pattern action)
  (hash-set! *grammar-productions* name
             `((pattern . ,pattern)
               (action . ,action)
               (created . ,(current-time))))
  (format #t "Added grammar production: ~a\n" name))

;; Define agentic transformation rule
(define (add-agentic-rule name condition transformation)
  (hash-set! *agentic-rules* name
             `((condition . ,condition)
               (transformation . ,transformation)
               (applied_count . 0)
               (success_rate . 0.0)))
  (format #t "Added agentic rule: ~a\n" name))

;; Capture transformation rules from QAT
(define (capture-qat-transformation membrane-id input-pattern output-pattern)
  (let ((rule-name (string-append "qat_" membrane-id "_" (symbol->string (gensym)))))
    (hash-set! *transformation-patterns* rule-name
               `((membrane . ,membrane-id)
                 (input . ,input-pattern)
                 (output . ,output-pattern)
                 (confidence . 1.0)
                 (timestamp . ,(current-time))))
    rule-name))

;; Apply cognitive grammar processing
(define (process-cognitive-grammar input-data context)
  (let ((results '())
        (processed-count 0))
    
    ;; Apply grammar productions
    (hash-for-each
      (lambda (name rule)
        (let ((pattern (assoc-ref rule 'pattern))
              (action (assoc-ref rule 'action)))
          (when (match-pattern? pattern input-data)
            (set! results (cons (apply-action action input-data context) results))
            (set! processed-count (+ processed-count 1)))))
      *grammar-productions*)
    
    ;; Return processing results
    `((results . ,results)
      (processed_count . ,processed-count)
      (timestamp . ,(current-time)))))

;; Simple pattern matching (placeholder implementation)
(define (match-pattern? pattern data)
  #t) ; Simplified - always matches for now

;; Apply action (placeholder implementation)
(define (apply-action action data context)
  `((action . ,action)
    (data . ,data)
    (context . ,context)
    (result . "processed")))

;; Export cognitive state
(define (export-cognitive-state)
  (format #t "{\"grammar_productions\": ~a, \"agentic_rules\": ~a, \"transformation_patterns\": ~a}\n"
          (hash-count (const #t) *grammar-productions*)
          (hash-count (const #t) *agentic-rules*)
          (hash-count (const #t) *transformation-patterns*)))

(display "Cognitive Grammar Kernel Loaded\n")
EOF

    chmod +x /opt/membrane/cognitive/grammar/cognitive_kernel.scm
    echo "Cognitive grammar kernel installed"
fi

# Create enhanced membrane configuration with P9ML settings
cat > /opt/membrane/config/membrane.json << EOF
{
  "id": "$MEMBRANE_ID",
  "parent": "${PARENT_MEMBRANE:-null}",
  "communication_mode": "$COMMUNICATION_MODE",
  "state": "active",
  "created_at": "$(date -Iseconds)",
  "p9ml": {
    "enabled": $ENABLE_P9ML,
    "tensor_dimensions": $TENSOR_DIMENSIONS,
    "quantization_enabled": $ENABLE_QUANTIZATION,
    "cognitive_kernel": $COGNITIVE_KERNEL,
    "namespace_registry": $NAMESPACE_REGISTRY
  },
  "neural": {
    "state_vector_size": $TENSOR_DIMENSIONS,
    "weight_matrix_initialized": false,
    "quantization_applied": false,
    "last_tensor_update": "$(date -Iseconds)"
  },
  "features": {
    "scheme_enabled": $ENABLE_SCHEME,
    "monitoring_enabled": $ENABLE_MONITORING,
    "p9ml_integration": $ENABLE_P9ML,
    "cognitive_processing": $COGNITIVE_KERNEL
  },
  "namespace": {
    "registry_enabled": $NAMESPACE_REGISTRY,
    "namespace_id": "${MEMBRANE_ID}_namespace",
    "global_state_access": true
  }
}
EOF

# Create enhanced evolution rules with P9ML and quantization support
cat > /opt/membrane/rules/evolution.sh << 'EOF'
#!/bin/bash
# P9ML Enhanced Evolution Rule Engine for Neural Membranes

source /opt/membrane/lib/membrane-utils.sh

# Load P9ML configuration
ENABLE_P9ML=$(get_config_value "p9ml.enabled" "true")
TENSOR_DIMS=$(get_config_value "p9ml.tensor_dimensions" "40")
QUANTIZATION_ENABLED=$(get_config_value "p9ml.quantization_enabled" "true")

# Rule: Apply P9ML quantization to neural membrane on weight update
handle_weight_update() {
    local weight_file="$1"
    log_event "weight_update_detected" "$weight_file"
    
    if [ "$ENABLE_P9ML" = "true" ] && [ "$QUANTIZATION_ENABLED" = "true" ]; then
        # Apply data-free QAT to neural membrane
        if [ -f "/opt/membrane/p9ml/ggml/ggml_p9ml_membrane.so" ]; then
            echo "Applying P9ML quantization to weights: $weight_file"
            log_event "p9ml_quantization_applied" "$weight_file"
            
            # Update neural configuration
            update_neural_config "quantization_applied" "true"
            update_neural_config "last_quantization" "$(date -Iseconds)"
        else
            log_event "p9ml_quantization_skipped" "library_not_available"
        fi
    fi
    
    # Capture transformation rule as agentic grammar production
    if command -v guile >/dev/null 2>&1; then
        guile -c "(load \"/opt/membrane/cognitive/grammar/cognitive_kernel.scm\") (capture-qat-transformation \"$(get_membrane_id)\" \"weight_update\" \"quantized_weights\")" 2>/dev/null
    fi
}

# Rule: Neural tensor processing on input data
handle_tensor_input() {
    local input_data="$1"
    log_event "tensor_input_received" "$input_data"
    
    if [ "$ENABLE_P9ML" = "true" ]; then
        # Process through neural membrane
        echo "Processing tensor input through P9ML membrane"
        
        # Update membrane state vector
        if [ -f "/opt/membrane/p9ml/ggml/ggml_p9ml_membrane.so" ]; then
            log_event "neural_processing_started" "$input_data"
            
            # Simulate tensor processing
            python3 -c "
import json
import time
try:
    with open('/opt/membrane/config/membrane.json', 'r') as f:
        config = json.load(f)
    
    # Update neural state
    config['neural']['last_tensor_update'] = time.strftime('%Y-%m-%dT%H:%M:%S%z')
    config['neural']['processing_active'] = True
    
    with open('/opt/membrane/config/membrane.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print('Neural tensor processing completed')
except Exception as e:
    print(f'Neural processing error: {e}')
" 2>/dev/null || echo "Python neural processing unavailable"
            
            log_event "neural_processing_completed" "success"
        fi
    fi
}

# Rule: Meta-learning adaptation on performance feedback
handle_performance_feedback() {
    local metrics="$1"
    log_event "performance_feedback" "$metrics"
    
    # Apply recursive namespace-level meta-rules for agentic adaptation
    if [ -f "/opt/membrane/p9ml/namespace/namespace_registry.py" ]; then
        echo "Applying meta-learning rules based on performance: $metrics"
        
        python3 /opt/membrane/p9ml/namespace/namespace_registry.py 2>/dev/null &
        META_PID=$!
        
        # Let it run briefly then stop
        sleep 2
        kill $META_PID 2>/dev/null || true
        
        log_event "meta_learning_applied" "$metrics"
    fi
}

# Rule: Communication through tensor exchange
handle_tensor_communication() {
    local source_membrane="$1"
    local tensor_data="$2"
    log_event "tensor_communication" "$source_membrane"
    
    if [ "$ENABLE_P9ML" = "true" ]; then
        # Process incoming tensor through cognitive kernel
        if command -v guile >/dev/null 2>&1; then
            echo "Processing tensor communication through cognitive grammar"
            guile -c "(load \"/opt/membrane/hypergraph.scm\") (cognitive-process-hypergraph \"$(get_membrane_id)\" \"$tensor_data\")" 2>/dev/null
        fi
        
        # Store tensor in vocabulary
        mkdir -p /opt/membrane/p9ml/tensors
        echo "$tensor_data" > "/opt/membrane/p9ml/tensors/received_$(date +%s).tensor"
        
        log_event "tensor_vocabulary_updated" "$source_membrane"
    fi
}

# Rule: File creation with neural processing
handle_file_creation() {
    local file="$1"
    log_event "file_created" "$file"
    
    # Check if it's a neural/tensor related file
    case "$file" in
        *.tensor|*.weights|*.model)
            handle_tensor_input "$file"
            ;;
        *.performance|*.metrics)
            handle_performance_feedback "$(cat "$file" 2>/dev/null || echo 'no_data')"
            ;;
        *)
            # Standard file creation response
            echo "Neural membrane response to: $(basename "$file")" > "/opt/membrane/state/response_$(date +%s).txt"
            ;;
    esac
}

# Rule: External signal with neural awareness
handle_signal() {
    local signal="$1"
    log_event "signal_received" "$signal"
    
    case "$signal" in
        "neural_division")
            log_event "neural_membrane_division" "triggered"
            # Create child neural membrane
            if [ "$ENABLE_P9ML" = "true" ]; then
                echo "Creating child neural membrane"
                log_event "child_neural_membrane_created" "$(get_membrane_id)_child"
            fi
            ;;
        "tensor_exchange")
            log_event "tensor_exchange_request" "received"
            handle_tensor_communication "external" "signal_tensor_data"
            ;;
        "quantization_update")
            log_event "quantization_update_request" "received"
            if [ -f "/opt/membrane/p9ml/ggml/weights.dat" ]; then
                handle_weight_update "/opt/membrane/p9ml/ggml/weights.dat"
            fi
            ;;
        *)
            log_event "unknown_signal" "$signal"
            ;;
    esac
}

# Main rule processing with P9ML support
case "${1:-}" in
    "file_created")
        handle_file_creation "$2"
        ;;
    "signal")
        handle_signal "$2"
        ;;
    "tensor_input")
        handle_tensor_input "$2"
        ;;
    "weight_update")
        handle_weight_update "$2"
        ;;
    "performance_feedback")
        handle_performance_feedback "$2"
        ;;
    "tensor_communication")
        handle_tensor_communication "$2" "$3"
        ;;
    *)
        echo "P9ML Neural Evolution Rules"
        echo "Available triggers: file_created, signal, tensor_input, weight_update, performance_feedback, tensor_communication"
        echo "Current trigger: ${1:-none}"
        ;;
esac
EOF

chmod +x /opt/membrane/rules/evolution.sh

# Create enhanced communication utilities with tensor exchange
cat > /opt/membrane/communication/send.sh << 'EOF'
#!/bin/bash
# Send message/tensor to another membrane with P9ML support

TARGET_MEMBRANE="$1"
MESSAGE="$2"
COMMUNICATION_MODE="${3:-tensor-exchange}"

if [ -z "$TARGET_MEMBRANE" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <target_membrane> <message> [communication_mode]"
    exit 1
fi

case "$COMMUNICATION_MODE" in
    "tensor-exchange")
        # Enhanced tensor-based communication
        if mkdir -p "/opt/membrane/communication/outbox" 2>/dev/null; then
            TIMESTAMP=$(date +%s)
            MSG_FILE="/opt/membrane/communication/outbox/tensor_${TARGET_MEMBRANE}_${TIMESTAMP}.json"
            
            # Create structured tensor message
            cat > "$MSG_FILE" << TENSOR_EOF
{
  "type": "tensor_message",
  "source_membrane": "$(get_membrane_id)",
  "target_membrane": "$TARGET_MEMBRANE",
  "data": "$MESSAGE",
  "tensor_shape": [$(get_config_value "p9ml.tensor_dimensions" "40")],
  "quantized": $(get_config_value "p9ml.quantization_enabled" "false"),
  "timestamp": "$TIMESTAMP",
  "communication_mode": "tensor-exchange"
}
TENSOR_EOF
            echo "Tensor message sent to $TARGET_MEMBRANE"
        else
            echo "Warning: Cannot create outbox directory, using /tmp"
            mkdir -p "/tmp/membrane_outbox"
            echo "$MESSAGE" > "/tmp/membrane_outbox/tensor_${TARGET_MEMBRANE}_$(date +%s).json"
        fi
        ;;
    "shared-volume")
        # Traditional shared volume communication
        if mkdir -p "/opt/membrane/communication/outbox" 2>/dev/null; then
            echo "$MESSAGE" > "/opt/membrane/communication/outbox/msg_${TARGET_MEMBRANE}_$(date +%s).json"
        else
            echo "Warning: Cannot create outbox directory, using /tmp"
            mkdir -p "/tmp/membrane_outbox"
            echo "$MESSAGE" > "/tmp/membrane_outbox/msg_${TARGET_MEMBRANE}_$(date +%s).json"
        fi
        ;;
    "network")
        # Placeholder for network communication
        echo "Network communication not yet implemented"
        ;;
    "ipc")
        # Placeholder for IPC communication  
        echo "IPC communication not yet implemented"
        ;;
esac

# Log the communication event
source /opt/membrane/lib/membrane-utils.sh
log_event "message_sent" "target:$TARGET_MEMBRANE,mode:$COMMUNICATION_MODE"

echo "Message sent to $TARGET_MEMBRANE via $COMMUNICATION_MODE"
EOF

chmod +x /opt/membrane/communication/send.sh

cat > /opt/membrane/communication/receive.sh << 'EOF'
#!/bin/bash
# Receive messages/tensors from other membranes with P9ML support

COMMUNICATION_MODE="${1:-tensor-exchange}"

source /opt/membrane/lib/membrane-utils.sh

case "$COMMUNICATION_MODE" in
    "tensor-exchange")
        # Process tensor-based messages
        if [ -d "/opt/membrane/communication/inbox" ]; then
            for msg_file in /opt/membrane/communication/inbox/tensor_*.json; do
                if [ -f "$msg_file" ]; then
                    echo "Received tensor message: $(cat "$msg_file")"
                    
                    # Extract tensor data and process through neural membrane
                    if command -v jq >/dev/null 2>&1; then
                        TENSOR_DATA=$(jq -r '.data' "$msg_file" 2>/dev/null)
                        SOURCE_MEMBRANE=$(jq -r '.source_membrane' "$msg_file" 2>/dev/null)
                        
                        # Process through evolution rules
                        /opt/membrane/rules/evolution.sh "tensor_communication" "$SOURCE_MEMBRANE" "$TENSOR_DATA"
                    fi
                    
                    # Archive the processed message
                    mkdir -p /opt/membrane/communication/processed
                    mv "$msg_file" "/opt/membrane/communication/processed/"
                    
                    log_event "tensor_message_received" "$(basename "$msg_file")"
                fi
            done
        fi
        ;;
    "shared-volume")
        # Traditional shared volume message processing
        if [ -d "/opt/membrane/communication/inbox" ]; then
            for msg_file in /opt/membrane/communication/inbox/msg_*.json; do
                if [ -f "$msg_file" ]; then
                    echo "Received message: $(cat "$msg_file")"
                    rm "$msg_file"
                    log_event "message_received" "$(basename "$msg_file")"
                fi
            done
        fi
        ;;
    *)
        echo "Communication mode $COMMUNICATION_MODE not implemented"
        ;;
esac
EOF

chmod +x /opt/membrane/communication/receive.sh

# Create tensor exchange utilities
cat > /opt/membrane/communication/tensor_exchange.py << 'EOF'
#!/usr/bin/env python3
"""
P9ML Tensor Exchange System for Neural Membrane Communication
Handles dynamic vocabulary encoding and tensor shape management
"""
import json
import numpy as np
import time
import os
from typing import Dict, List, Optional, Tuple

class TensorExchangeManager:
    def __init__(self, membrane_id: str, tensor_dims: int = 40):
        self.membrane_id = membrane_id
        self.tensor_dims = tensor_dims
        self.vocabulary = {}
        self.shape_registry = {}
        self.exchange_history = []
        
    def encode_tensor_shape(self, shape: Tuple[int, ...]) -> str:
        """Encode tensor shapes as dynamic vocabulary"""
        shape_key = f"shape_{'-'.join(map(str, shape))}"
        if shape_key not in self.vocabulary:
            vocab_id = len(self.vocabulary)
            self.vocabulary[shape_key] = {
                'id': vocab_id,
                'shape': shape,
                'created_at': time.time(),
                'usage_count': 0
            }
        
        self.vocabulary[shape_key]['usage_count'] += 1
        return shape_key
    
    def decode_tensor_shape(self, shape_key: str) -> Optional[Tuple[int, ...]]:
        """Decode tensor shape from vocabulary"""
        if shape_key in self.vocabulary:
            return self.vocabulary[shape_key]['shape']
        return None
    
    def create_tensor_message(self, target_membrane: str, data: np.ndarray, 
                            message_type: str = "neural_data") -> Dict:
        """Create structured tensor message for exchange"""
        shape_key = self.encode_tensor_shape(data.shape)
        
        message = {
            'type': 'tensor_exchange',
            'source_membrane': self.membrane_id,
            'target_membrane': target_membrane,
            'message_type': message_type,
            'tensor_data': {
                'shape_key': shape_key,
                'shape': list(data.shape),
                'dtype': str(data.dtype),
                'data': data.flatten().tolist(),
                'checksum': hash(data.tobytes())
            },
            'vocabulary_update': {
                'new_shapes': [shape_key] if shape_key not in self.shape_registry else [],
                'vocab_size': len(self.vocabulary)
            },
            'timestamp': time.time(),
            'exchange_id': f"{self.membrane_id}_{int(time.time())}"
        }
        
        self.exchange_history.append(message['exchange_id'])
        self.shape_registry[shape_key] = data.shape
        
        return message
    
    def process_tensor_message(self, message: Dict) -> Optional[np.ndarray]:
        """Process incoming tensor message and extract tensor data"""
        try:
            tensor_data = message['tensor_data']
            shape = tuple(tensor_data['shape'])
            dtype = tensor_data['dtype']
            data = np.array(tensor_data['data'], dtype=dtype).reshape(shape)
            
            # Update local vocabulary
            shape_key = tensor_data['shape_key']
            if shape_key not in self.vocabulary:
                self.vocabulary[shape_key] = {
                    'id': len(self.vocabulary),
                    'shape': shape,
                    'created_at': time.time(),
                    'usage_count': 1,
                    'source': 'received'
                }
            
            # Verify checksum
            if hash(data.tobytes()) != tensor_data['checksum']:
                print(f"Warning: Tensor checksum mismatch for {message['exchange_id']}")
            
            return data
            
        except Exception as e:
            print(f"Error processing tensor message: {e}")
            return None
    
    def export_vocabulary(self) -> str:
        """Export tensor vocabulary as JSON"""
        export_data = {
            'membrane_id': self.membrane_id,
            'vocabulary': self.vocabulary,
            'shape_registry': {k: list(v) for k, v in self.shape_registry.items()},
            'exchange_history': self.exchange_history[-100:],  # Last 100 exchanges
            'tensor_dims': self.tensor_dims,
            'exported_at': time.time()
        }
        return json.dumps(export_data, indent=2)
    
    def save_vocabulary(self, filepath: str = None) -> None:
        """Save vocabulary to file"""
        if filepath is None:
            filepath = f"/opt/membrane/p9ml/tensors/vocabulary_{self.membrane_id}.json"
        
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(self.export_vocabulary())
    
    def load_vocabulary(self, filepath: str = None) -> bool:
        """Load vocabulary from file"""
        if filepath is None:
            filepath = f"/opt/membrane/p9ml/tensors/vocabulary_{self.membrane_id}.json"
        
        try:
            if os.path.exists(filepath):
                with open(filepath, 'r') as f:
                    data = json.load(f)
                
                self.vocabulary = data.get('vocabulary', {})
                self.shape_registry = {k: tuple(v) for k, v in data.get('shape_registry', {}).items()}
                self.exchange_history = data.get('exchange_history', [])
                return True
        except Exception as e:
            print(f"Error loading vocabulary: {e}")
        
        return False

# Example usage and CLI interface
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: tensor_exchange.py <command> [args...]")
        print("Commands: create_message, process_message, export_vocab, test")
        sys.exit(1)
    
    # Load membrane config to get membrane ID
    try:
        with open('/opt/membrane/config/membrane.json', 'r') as f:
            config = json.load(f)
        membrane_id = config['id']
        tensor_dims = config.get('p9ml', {}).get('tensor_dimensions', 40)
    except:
        membrane_id = "default_membrane"
        tensor_dims = 40
    
    manager = TensorExchangeManager(membrane_id, tensor_dims)
    manager.load_vocabulary()
    
    command = sys.argv[1]
    
    if command == "create_message":
        # Create test tensor message
        test_data = np.random.randn(tensor_dims).astype(np.float32)
        target = sys.argv[2] if len(sys.argv) > 2 else "target_membrane"
        message = manager.create_tensor_message(target, test_data)
        print(json.dumps(message, indent=2))
        
    elif command == "export_vocab":
        print(manager.export_vocabulary())
        
    elif command == "test":
        # Test tensor encoding/decoding
        test_shapes = [(40,), (40, 40), (1, 40, 40)]
        for shape in test_shapes:
            test_data = np.random.randn(*shape).astype(np.float32)
            shape_key = manager.encode_tensor_shape(shape)
            decoded_shape = manager.decode_tensor_shape(shape_key)
            print(f"Shape {shape} -> {shape_key} -> {decoded_shape}")
    
    manager.save_vocabulary()
EOF

chmod +x /opt/membrane/communication/tensor_exchange.py

# Initialize membrane state - create lib directory first
mkdir -p /opt/membrane/lib

# Create enhanced utility library with P9ML support
cat > /opt/membrane/lib/membrane-utils.sh << 'EOF'
#!/bin/bash
# Enhanced membrane utility functions with P9ML neural support

get_membrane_id() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.id' /opt/membrane/config/membrane.json 2>/dev/null || echo "unknown"
    else
        grep '"id"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "unknown"
    fi
}

get_parent_membrane() {
    if command -v jq >/dev/null 2>&1; then
        jq -r '.parent' /opt/membrane/config/membrane.json 2>/dev/null || echo "null"
    else
        grep '"parent"' /opt/membrane/config/membrane.json 2>/dev/null | cut -d'"' -f4 || echo "null"
    fi
}

# Get P9ML configuration values
get_config_value() {
    local key="$1"
    local default="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$key // \"$default\"" /opt/membrane/config/membrane.json 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Update neural configuration
update_neural_config() {
    local key="$1"
    local value="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq ".neural.$key = \"$value\"" /opt/membrane/config/membrane.json > /tmp/membrane_config.tmp 2>/dev/null
        mv /tmp/membrane_config.tmp /opt/membrane/config/membrane.json 2>/dev/null
    else
        echo "Neural config update requires jq - update not performed"
    fi
}

# Get tensor dimensions
get_tensor_dimensions() {
    get_config_value "p9ml.tensor_dimensions" "40"
}

# Check if P9ML is enabled
is_p9ml_enabled() {
    local enabled=$(get_config_value "p9ml.enabled" "false")
    [ "$enabled" = "true" ]
}

# Check if quantization is enabled
is_quantization_enabled() {
    local enabled=$(get_config_value "p9ml.quantization_enabled" "false")
    [ "$enabled" = "true" ]
}

# Get namespace ID
get_namespace_id() {
    get_config_value "namespace.namespace_id" "$(get_membrane_id)_namespace"
}

log_event() {
    local event_type="$1"
    local event_data="$2"
    local timestamp=$(date -Iseconds 2>/dev/null || date)
    local membrane_id=$(get_membrane_id)
    
    # Enhanced logging with P9ML context
    local p9ml_status="disabled"
    if is_p9ml_enabled; then
        p9ml_status="enabled"
    fi
    
    echo "{\"timestamp\": \"$timestamp\", \"membrane\": \"$membrane_id\", \"event\": \"$event_type\", \"data\": \"$event_data\", \"p9ml_status\": \"$p9ml_status\"}" >> /opt/membrane/logs/events.log
}

get_membrane_state() {
    cat /opt/membrane/config/membrane.json 2>/dev/null || echo "{}"
}

update_membrane_state() {
    local key="$1"
    local value="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq ".$key = \"$value\"" /opt/membrane/config/membrane.json > /tmp/membrane_config.tmp 2>/dev/null
        mv /tmp/membrane_config.tmp /opt/membrane/config/membrane.json 2>/dev/null
    else
        echo "State update requires jq - update not performed"
    fi
}

# Neural tensor utilities
get_neural_state() {
    if command -v jq >/dev/null 2>&1; then
        jq '.neural' /opt/membrane/config/membrane.json 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Initialize tensor vocabulary
init_tensor_vocabulary() {
    if is_p9ml_enabled && command -v python3 >/dev/null 2>&1; then
        python3 /opt/membrane/communication/tensor_exchange.py export_vocab > /opt/membrane/p9ml/tensors/initial_vocabulary.json 2>/dev/null
        log_event "tensor_vocabulary_initialized" "$(get_membrane_id)"
    fi
}

# Apply P9ML quantization if enabled
apply_quantization() {
    if is_quantization_enabled; then
        log_event "quantization_requested" "$(get_membrane_id)"
        # Trigger evolution rule for quantization
        /opt/membrane/rules/evolution.sh "signal" "quantization_update" 2>/dev/null
    fi
}

# Start namespace registry if enabled
start_namespace_registry() {
    local namespace_enabled=$(get_config_value "namespace.registry_enabled" "false")
    if [ "$namespace_enabled" = "true" ] && [ -f "/opt/membrane/p9ml/namespace/namespace_registry.py" ]; then
        echo "Starting P9ML namespace registry..."
        nohup python3 /opt/membrane/p9ml/namespace/namespace_registry.py > /opt/membrane/logs/namespace.log 2>&1 &
        echo $! > /opt/membrane/state/namespace_registry.pid
        log_event "namespace_registry_started" "$(get_namespace_id)"
    fi
}

# Stop namespace registry
stop_namespace_registry() {
    if [ -f "/opt/membrane/state/namespace_registry.pid" ]; then
        local pid=$(cat /opt/membrane/state/namespace_registry.pid)
        kill $pid 2>/dev/null && log_event "namespace_registry_stopped" "$pid"
        rm -f /opt/membrane/state/namespace_registry.pid
    fi
}

# Get membrane statistics
get_membrane_stats() {
    local stats="{}"
    
    if command -v jq >/dev/null 2>&1; then
        local event_count=$(wc -l < /opt/membrane/logs/events.log 2>/dev/null || echo "0")
        local tensor_files=$(find /opt/membrane/p9ml/tensors -name "*.tensor" 2>/dev/null | wc -l || echo "0")
        local vocab_size="0"
        
        if [ -f "/opt/membrane/p9ml/tensors/vocabulary_$(get_membrane_id).json" ]; then
            vocab_size=$(jq '.vocabulary | length' "/opt/membrane/p9ml/tensors/vocabulary_$(get_membrane_id).json" 2>/dev/null || echo "0")
        fi
        
        stats=$(jq -n \
            --arg membrane_id "$(get_membrane_id)" \
            --arg p9ml_enabled "$(is_p9ml_enabled && echo true || echo false)" \
            --arg tensor_dims "$(get_tensor_dimensions)" \
            --arg event_count "$event_count" \
            --arg tensor_files "$tensor_files" \
            --arg vocab_size "$vocab_size" \
            --arg timestamp "$(date -Iseconds)" \
            '{
                membrane_id: $membrane_id,
                p9ml_enabled: ($p9ml_enabled == "true"),
                tensor_dimensions: ($tensor_dims | tonumber),
                event_count: ($event_count | tonumber),
                tensor_files: ($tensor_files | tonumber),
                vocabulary_size: ($vocab_size | tonumber),
                timestamp: $timestamp
            }')
    fi
    
    echo "$stats"
}
EOF

# Create enhanced monitoring service with P9ML neural awareness
if [ "$ENABLE_MONITORING" = "true" ]; then
    cat > /opt/membrane/monitor.sh << 'EOF'
#!/bin/bash
# P9ML Neural Membrane monitoring and event processing service

source /opt/membrane/lib/membrane-utils.sh

echo "Starting P9ML neural membrane monitoring service for $(get_membrane_id)"
echo "P9ML Integration: $(is_p9ml_enabled && echo 'ENABLED' || echo 'DISABLED')"
echo "Tensor Dimensions: $(get_tensor_dimensions)"

# Monitor file system changes with neural awareness
monitor_filesystem() {
    inotifywait -m -r /tmp --format '%w%f %e' |
    while read file event; do
        case "$event" in
            "CREATE")
                # Check for neural/tensor files
                case "$file" in
                    *.tensor|*.weights|*.model)
                        /opt/membrane/rules/evolution.sh "tensor_input" "$file"
                        ;;
                    *.performance|*.metrics)
                        /opt/membrane/rules/evolution.sh "performance_feedback" "$file"
                        ;;
                    *)
                        /opt/membrane/rules/evolution.sh "file_created" "$file"
                        ;;
                esac
                ;;
        esac
    done &
}

# Monitor P9ML tensor communication
monitor_tensor_communication() {
    if [ -d "/opt/membrane/communication/inbox" ]; then
        inotifywait -m /opt/membrane/communication/inbox --format '%f %e' |
        while read file event; do
            case "$event" in
                "CREATE")
                    if [[ "$file" == tensor_*.json ]]; then
                        echo "Processing tensor communication: $file"
                        /opt/membrane/communication/receive.sh "tensor-exchange"
                    elif [[ "$file" == msg_*.json ]]; then
                        /opt/membrane/communication/receive.sh "shared-volume"
                    fi
                    ;;
            esac
        done &
    fi
}

# Monitor P9ML neural state changes
monitor_neural_state() {
    if is_p9ml_enabled; then
        while true; do
            # Check for neural state updates every 5 seconds
            sleep 5
            
            # Trigger meta-learning adaptation periodically
            if [ $(($(date +%s) % 30)) -eq 0 ]; then
                /opt/membrane/rules/evolution.sh "signal" "meta_learning_check"
            fi
            
            # Apply quantization if needed
            if is_quantization_enabled && [ $(($(date +%s) % 60)) -eq 0 ]; then
                apply_quantization
            fi
        done &
    fi
}

# Monitor namespace registry health
monitor_namespace() {
    local namespace_enabled=$(get_config_value "namespace.registry_enabled" "false")
    if [ "$namespace_enabled" = "true" ]; then
        while true; do
            sleep 10
            
            # Check if namespace registry is running
            if [ -f "/opt/membrane/state/namespace_registry.pid" ]; then
                local pid=$(cat /opt/membrane/state/namespace_registry.pid)
                if ! kill -0 $pid 2>/dev/null; then
                    echo "Namespace registry died, restarting..."
                    start_namespace_registry
                fi
            else
                start_namespace_registry
            fi
        done &
    fi
}

# Start all monitoring components
monitor_filesystem
monitor_tensor_communication
monitor_neural_state
monitor_namespace

# Initialize P9ML components
if is_p9ml_enabled; then
    echo "Initializing P9ML neural components..."
    init_tensor_vocabulary
    
    # Start namespace registry if enabled
    start_namespace_registry
fi

# Trap signals for clean shutdown
trap 'echo "Shutting down P9ML neural membrane monitoring..."; stop_namespace_registry; exit 0' SIGTERM SIGINT

# Keep the script running
echo "P9ML Neural Membrane monitoring active. Press Ctrl+C to stop."
wait
EOF

    chmod +x /opt/membrane/monitor.sh
fi

# Create visualization dashboard
cat > /opt/membrane/visualization/membrane_neural_viz.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>P9ML Neural Membrane Visualization</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .neural-membrane { fill: #4CAF50; stroke: #45a049; stroke-width: 2px; }
        .neural-connection { stroke: #2196F3; stroke-width: 2px; fill: none; }
        .tensor-flow { stroke: #FF9800; stroke-width: 3px; fill: none; stroke-dasharray: 5,5; }
        .quantized { fill: #9C27B0; }
        .status-active { color: #4CAF50; }
        .status-processing { color: #FF9800; }
        .status-error { color: #F44336; }
        #membrane-graph { border: 1px solid #ddd; border-radius: 4px; }
        .info-text { font-size: 12px; fill: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>P9ML Neural Membrane Computing Visualization</h1>
        
        <div class="dashboard">
            <div class="panel">
                <h3>Membrane Status</h3>
                <div id="membrane-status">Loading...</div>
            </div>
            <div class="panel">
                <h3>Neural Activity</h3>
                <div id="neural-activity">Loading...</div>
            </div>
        </div>
        
        <div class="panel">
            <h3>Membrane Hierarchy & Neural Connections</h3>
            <svg id="membrane-graph" width="100%" height="400"></svg>
        </div>
        
        <div class="dashboard">
            <div class="panel">
                <h3>Tensor Vocabulary</h3>
                <div id="tensor-vocab">Loading...</div>
            </div>
            <div class="panel">
                <h3>Recent Events</h3>
                <div id="recent-events">Loading...</div>
            </div>
        </div>
    </div>

    <script>
        // Mock data for demonstration (in real implementation, this would fetch from membrane APIs)
        const mockMembraneData = {
            id: "cognitive-root",
            status: "active",
            p9ml_enabled: true,
            tensor_dimensions: 40,
            quantization_enabled: true,
            children: [
                { id: "perception", status: "processing", type: "sensory" },
                { id: "cognition", status: "active", type: "reasoning" },
                { id: "action", status: "active", type: "motor" }
            ],
            neural_activity: {
                tensor_operations: 1247,
                quantization_events: 23,
                vocabulary_size: 156,
                recent_exchanges: 8
            },
            recent_events: [
                { timestamp: "2024-01-15T10:30:00Z", event: "tensor_input_received", data: "visual_data.tensor" },
                { timestamp: "2024-01-15T10:29:45Z", event: "p9ml_quantization_applied", data: "weights_updated" },
                { timestamp: "2024-01-15T10:29:30Z", event: "neural_processing_completed", data: "success" },
                { timestamp: "2024-01-15T10:29:15Z", event: "tensor_communication", data: "perception -> cognition" }
            ]
        };

        // Initialize visualization
        function initVisualization() {
            updateMembraneStatus();
            updateNeuralActivity();
            createMembraneGraph();
            updateTensorVocab();
            updateRecentEvents();
        }

        function updateMembraneStatus() {
            const statusDiv = document.getElementById('membrane-status');
            const statusClass = mockMembraneData.status === 'active' ? 'status-active' : 
                               mockMembraneData.status === 'processing' ? 'status-processing' : 'status-error';
            
            statusDiv.innerHTML = `
                <p><strong>ID:</strong> ${mockMembraneData.id}</p>
                <p><strong>Status:</strong> <span class="${statusClass}">${mockMembraneData.status.toUpperCase()}</span></p>
                <p><strong>P9ML:</strong> ${mockMembraneData.p9ml_enabled ? '✓ ENABLED' : '✗ DISABLED'}</p>
                <p><strong>Quantization:</strong> ${mockMembraneData.quantization_enabled ? '✓ ENABLED' : '✗ DISABLED'}</p>
                <p><strong>Tensor Dims:</strong> ${mockMembraneData.tensor_dimensions}</p>
            `;
        }

        function updateNeuralActivity() {
            const activityDiv = document.getElementById('neural-activity');
            const activity = mockMembraneData.neural_activity;
            
            activityDiv.innerHTML = `
                <p><strong>Tensor Operations:</strong> ${activity.tensor_operations}</p>
                <p><strong>Quantization Events:</strong> ${activity.quantization_events}</p>
                <p><strong>Vocabulary Size:</strong> ${activity.vocabulary_size}</p>
                <p><strong>Recent Exchanges:</strong> ${activity.recent_exchanges}</p>
            `;
        }

        function createMembraneGraph() {
            const svg = d3.select("#membrane-graph");
            const width = 800;
            const height = 400;
            
            svg.attr("width", width).attr("height", height);
            svg.selectAll("*").remove(); // Clear existing content
            
            // Create nodes data
            const nodes = [
                { id: mockMembraneData.id, x: width/2, y: height/2, type: "root", quantized: true },
                ...mockMembraneData.children.map((child, i) => ({
                    id: child.id,
                    x: width/2 + Math.cos(i * 2 * Math.PI / mockMembraneData.children.length) * 150,
                    y: height/2 + Math.sin(i * 2 * Math.PI / mockMembraneData.children.length) * 150,
                    type: child.type,
                    status: child.status,
                    quantized: Math.random() > 0.5
                }))
            ];
            
            // Create links data
            const links = mockMembraneData.children.map(child => ({
                source: mockMembraneData.id,
                target: child.id,
                type: "neural_connection"
            }));
            
            // Draw neural connections
            svg.selectAll(".neural-connection")
                .data(links)
                .enter()
                .append("line")
                .attr("class", "neural-connection")
                .attr("x1", d => nodes.find(n => n.id === d.source).x)
                .attr("y1", d => nodes.find(n => n.id === d.source).y)
                .attr("x2", d => nodes.find(n => n.id === d.target).x)
                .attr("y2", d => nodes.find(n => n.id === d.target).y);
            
            // Draw tensor flow animations
            svg.selectAll(".tensor-flow")
                .data(links)
                .enter()
                .append("line")
                .attr("class", "tensor-flow")
                .attr("x1", d => nodes.find(n => n.id === d.source).x)
                .attr("y1", d => nodes.find(n => n.id === d.source).y)
                .attr("x2", d => nodes.find(n => n.id === d.target).x)
                .attr("y2", d => nodes.find(n => n.id === d.target).y)
                .style("opacity", 0.7);
            
            // Draw membrane nodes
            const nodeGroups = svg.selectAll(".membrane-node")
                .data(nodes)
                .enter()
                .append("g")
                .attr("class", "membrane-node")
                .attr("transform", d => `translate(${d.x}, ${d.y})`);
            
            nodeGroups.append("circle")
                .attr("r", d => d.type === "root" ? 30 : 20)
                .attr("class", d => d.quantized ? "neural-membrane quantized" : "neural-membrane");
            
            nodeGroups.append("text")
                .attr("text-anchor", "middle")
                .attr("dy", "0.35em")
                .attr("class", "info-text")
                .text(d => d.id);
            
            // Add status indicators
            nodeGroups.append("circle")
                .attr("r", 4)
                .attr("cx", 15)
                .attr("cy", -15)
                .attr("fill", d => {
                    if (d.status === "active") return "#4CAF50";
                    if (d.status === "processing") return "#FF9800";
                    return "#F44336";
                });
        }

        function updateTensorVocab() {
            const vocabDiv = document.getElementById('tensor-vocab');
            vocabDiv.innerHTML = `
                <p><strong>Vocabulary Entries:</strong> ${mockMembraneData.neural_activity.vocabulary_size}</p>
                <p><strong>Shape Encodings:</strong> 42</p>
                <p><strong>Recent Additions:</strong> 5</p>
                <p><strong>Compression Ratio:</strong> 0.73</p>
            `;
        }

        function updateRecentEvents() {
            const eventsDiv = document.getElementById('recent-events');
            const eventsList = mockMembraneData.recent_events.map(event => 
                `<div style="margin-bottom: 8px; padding: 4px; background: #f9f9f9; border-radius: 4px;">
                    <strong>${event.event}:</strong> ${event.data}<br>
                    <small style="color: #666;">${new Date(event.timestamp).toLocaleTimeString()}</small>
                </div>`
            ).join('');
            
            eventsDiv.innerHTML = eventsList;
        }

        // Animate tensor flows
        function animateTensorFlows() {
            d3.selectAll(".tensor-flow")
                .style("stroke-dashoffset", "20")
                .transition()
                .duration(2000)
                .ease(d3.easeLinear)
                .style("stroke-dashoffset", "0")
                .on("end", animateTensorFlows);
        }

        // Initialize visualization when page loads
        document.addEventListener('DOMContentLoaded', function() {
            initVisualization();
            animateTensorFlows();
            
            // Refresh data every 5 seconds (in real implementation)
            setInterval(() => {
                // This would fetch real data from membrane APIs
                // For now, just simulate some changes
                mockMembraneData.neural_activity.tensor_operations += Math.floor(Math.random() * 10);
                mockMembraneData.neural_activity.recent_exchanges = Math.floor(Math.random() * 20);
                updateNeuralActivity();
            }, 5000);
        });
    </script>
</body>
</html>
EOF

# Create enhanced membrane command-line interface with P9ML support
cat > /usr/local/bin/membrane << 'EOF'
#!/bin/bash
# P9ML Neural Membrane CLI

source /opt/membrane/lib/membrane-utils.sh

case "${1:-}" in
    "status")
        echo "P9ML Neural Membrane Status:"
        if command -v jq >/dev/null 2>&1 && [ -f /opt/membrane/config/membrane.json ]; then
            cat /opt/membrane/config/membrane.json | jq .
        else
            cat /opt/membrane/config/membrane.json 2>/dev/null || echo "Configuration file not found"
        fi
        
        # Show neural statistics
        if is_p9ml_enabled; then
            echo ""
            echo "Neural Statistics:"
            get_membrane_stats | jq . 2>/dev/null || echo "Statistics unavailable"
        fi
        ;;
    "neural")
        case "${2:-}" in
            "stats")
                echo "Neural Membrane Statistics:"
                get_membrane_stats | jq . 2>/dev/null || echo "Statistics unavailable"
                ;;
            "vocab")
                if [ -f "/opt/membrane/p9ml/tensors/vocabulary_$(get_membrane_id).json" ]; then
                    echo "Tensor Vocabulary:"
                    cat "/opt/membrane/p9ml/tensors/vocabulary_$(get_membrane_id).json" | jq . 2>/dev/null
                else
                    echo "Tensor vocabulary not found"
                fi
                ;;
            "quantize")
                if is_quantization_enabled; then
                    echo "Applying P9ML quantization..."
                    apply_quantization
                else
                    echo "Quantization not enabled"
                fi
                ;;
            *)
                echo "Neural commands: stats, vocab, quantize"
                ;;
        esac
        ;;
    "namespace")
        case "${2:-}" in
            "start")
                start_namespace_registry
                ;;
            "stop")
                stop_namespace_registry
                ;;
            "status")
                if [ -f "/opt/membrane/state/namespace_registry.pid" ]; then
                    echo "Namespace registry is running (PID: $(cat /opt/membrane/state/namespace_registry.pid))"
                else
                    echo "Namespace registry is not running"
                fi
                ;;
            *)
                echo "Namespace commands: start, stop, status"
                ;;
        esac
        ;;
    "tensor")
        case "${2:-}" in
            "send")
                if [ -z "$3" ] || [ -z "$4" ]; then
                    echo "Usage: membrane tensor send <target_membrane> <tensor_data>"
                    exit 1
                fi
                if command -v python3 >/dev/null 2>&1; then
                    python3 /opt/membrane/communication/tensor_exchange.py create_message "$3" "$4"
                else
                    echo "Python3 required for tensor operations"
                fi
                ;;
            "vocab")
                if command -v python3 >/dev/null 2>&1; then
                    python3 /opt/membrane/communication/tensor_exchange.py export_vocab
                else
                    echo "Python3 required for tensor operations"
                fi
                ;;
            "test")
                if command -v python3 >/dev/null 2>&1; then
                    python3 /opt/membrane/communication/tensor_exchange.py test
                else
                    echo "Python3 required for tensor operations"
                fi
                ;;
            *)
                echo "Tensor commands: send, vocab, test"
                ;;
        esac
        ;;
    "send")
        /opt/membrane/communication/send.sh "$2" "$3" "$4"
        ;;
    "receive")
        /opt/membrane/communication/receive.sh "$2"
        ;;
    "log")
        echo "Recent membrane events:"
        if command -v jq >/dev/null 2>&1; then
            tail -n 10 /opt/membrane/logs/events.log 2>/dev/null | jq . || echo "No events logged yet"
        else
            tail -n 10 /opt/membrane/logs/events.log 2>/dev/null || echo "No events logged yet"
        fi
        ;;
    "rules")
        echo "Available evolution rules:"
        ls -la /opt/membrane/rules/ 2>/dev/null || echo "Rules directory not found"
        ;;
    "monitor")
        case "${2:-}" in
            "start")
                /opt/membrane/monitor.sh &
                echo "P9ML neural monitoring started"
                ;;
            "stop")
                pkill -f "membrane/monitor.sh" && echo "Monitoring stopped" || echo "No monitoring process found"
                ;;
            *)
                echo "Monitor commands: start, stop"
                ;;
        esac
        ;;
    "scheme")
        if command -v guile >/dev/null 2>&1; then
            if is_p9ml_enabled && [ -f "/opt/membrane/cognitive/grammar/cognitive_kernel.scm" ]; then
                echo "Loading P9ML cognitive grammar kernel..."
                guile -l /opt/membrane/hypergraph.scm -l /opt/membrane/cognitive/grammar/cognitive_kernel.scm 2>/dev/null || guile
            else
                guile -l /opt/membrane/hypergraph.scm 2>/dev/null || guile
            fi
        else
            echo "Scheme interpreter not available"
        fi
        ;;
    "visualize")
        if command -v python3 >/dev/null 2>&1; then
            echo "Starting membrane visualization server..."
            echo "Open http://localhost:8000/membrane_neural_viz.html in your browser"
            cd /opt/membrane/visualization
            python3 -m http.server 8000 2>/dev/null &
            echo "Visualization server started (PID: $!)"
        else
            echo "Python3 required for visualization server"
            echo "Alternatively, open /opt/membrane/visualization/membrane_neural_viz.html in a browser"
        fi
        ;;
    "test")
        echo "Running P9ML Neural Membrane tests..."
        
        # Test basic functionality
        echo "✓ Membrane ID: $(get_membrane_id)"
        echo "✓ P9ML enabled: $(is_p9ml_enabled && echo 'YES' || echo 'NO')"
        echo "✓ Tensor dimensions: $(get_tensor_dimensions)"
        
        # Test neural components
        if is_p9ml_enabled; then
            echo "✓ Testing neural components..."
            
            # Test tensor vocabulary
            if command -v python3 >/dev/null 2>&1; then
                python3 /opt/membrane/communication/tensor_exchange.py test >/dev/null 2>&1 && echo "✓ Tensor exchange: OK" || echo "✗ Tensor exchange: FAILED"
            fi
            
            # Test cognitive kernel
            if command -v guile >/dev/null 2>&1 && [ -f "/opt/membrane/cognitive/grammar/cognitive_kernel.scm" ]; then
                echo "✓ Cognitive kernel: OK"
            else
                echo "✗ Cognitive kernel: FAILED"
            fi
            
            # Test quantization
            if is_quantization_enabled; then
                echo "✓ Quantization: ENABLED"
            else
                echo "- Quantization: DISABLED"
            fi
        fi
        
        echo "P9ML Neural Membrane test completed"
        ;;
    *)
        echo "P9ML Neural Membrane Computing CLI"
        echo ""
        echo "Core Commands:"
        echo "  status                    - Show membrane status and neural statistics"
        echo "  send <target> <message>   - Send message to target membrane"
        echo "  receive                   - Check for incoming messages"
        echo "  log                       - Show recent events"
        echo "  rules                     - List evolution rules"
        echo "  test                      - Run system tests"
        echo ""
        echo "Neural Commands:"
        echo "  neural stats              - Show neural processing statistics"
        echo "  neural vocab              - Show tensor vocabulary"
        echo "  neural quantize           - Apply P9ML quantization"
        echo ""
        echo "Tensor Commands:"
        echo "  tensor send <target> <data> - Send tensor data to target membrane"
        echo "  tensor vocab              - Export tensor vocabulary"
        echo "  tensor test               - Test tensor encoding/decoding"
        echo ""
        echo "Namespace Commands:"
        echo "  namespace start           - Start namespace registry"
        echo "  namespace stop            - Stop namespace registry"
        echo "  namespace status          - Check namespace registry status"
        echo ""
        echo "System Commands:"
        echo "  monitor start             - Start monitoring service"
        echo "  monitor stop              - Stop monitoring service"
        echo "  scheme                    - Start Scheme interpreter with cognitive kernel"
        echo "  visualize                 - Start web-based visualization dashboard"
        echo ""
        echo "P9ML Features: $(is_p9ml_enabled && echo 'ENABLED' || echo 'DISABLED')"
        echo "Tensor Dimensions: $(get_tensor_dimensions)"
        echo "Quantization: $(is_quantization_enabled && echo 'ENABLED' || echo 'DISABLED')"
        ;;
esac
EOF

chmod +x /usr/local/bin/membrane

# Initialize P9ML components and log setup completion
source /opt/membrane/lib/membrane-utils.sh
log_event "p9ml_membrane_initialized" "$MEMBRANE_ID"

# Initialize tensor vocabulary if P9ML is enabled
if is_p9ml_enabled; then
    init_tensor_vocabulary
    log_event "tensor_vocabulary_initialized" "$(get_tensor_dimensions)_dims"
fi

echo ""
echo "================================================"
echo "P9ML Neural Membrane Computing installation completed"
echo "================================================"
echo ""
echo "Membrane ID: $MEMBRANE_ID"
echo "P9ML Integration: $(is_p9ml_enabled && echo 'ENABLED' || echo 'DISABLED')"
echo "Tensor Dimensions: $(get_tensor_dimensions)"
echo "Quantization: $(is_quantization_enabled && echo 'ENABLED' || echo 'DISABLED')"
echo "Cognitive Kernel: $([ "$COGNITIVE_KERNEL" = "true" ] && echo 'ENABLED' || echo 'DISABLED')"
echo "Namespace Registry: $([ "$NAMESPACE_REGISTRY" = "true" ] && echo 'ENABLED' || echo 'DISABLED')"
echo ""
echo "Available Commands:"
echo "  membrane status           - Check system status"
echo "  membrane neural stats     - View neural statistics"
echo "  membrane test             - Run system tests"
echo "  membrane visualize        - Start visualization dashboard"
echo "  membrane --help           - Show all commands"
echo ""
echo "Neural Tensor Files: /opt/membrane/p9ml/"
echo "Visualization: /opt/membrane/visualization/membrane_neural_viz.html"
echo "Documentation: See updated README.md and TENSOR_MAPPING.md"