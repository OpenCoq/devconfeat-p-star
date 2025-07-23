;;; Cognitive P-System Hypergraph Representation
;;; This file demonstrates the Scheme-based representation of 
;;; the cognitive architecture as P-system membranes

(use-modules (ice-9 format))

;; Load the basic hypergraph library
(load "/opt/membrane/hypergraph.scm")

;; Define the cognitive root membrane
(define cognitive-root
  (create-membrane-node "cognitive-root"))

;; Define main subsystem membranes
(define perception-membrane
  (create-membrane-node "perception"))

(define cognition-membrane  
  (create-membrane-node "cognition"))

(define action-membrane
  (create-membrane-node "action"))

;; Create nesting relationships for main subsystems
(define perception-nesting
  (create-nesting-link "perception" "cognitive-root"))

(define cognition-nesting
  (create-nesting-link "cognition" "cognitive-root"))

(define action-nesting
  (create-nesting-link "action" "cognitive-root"))

;; Define worker membranes in perception subsystem
(define visual-worker
  (create-membrane-node "perception-visual"))

(define audio-worker
  (create-membrane-node "perception-audio"))

;; Create nesting for perception workers
(define visual-nesting
  (create-nesting-link "perception-visual" "perception"))

(define audio-nesting
  (create-nesting-link "perception-audio" "perception"))

;; Define cognition subsystem membranes
(define reasoning-engine
  (create-membrane-node "cognition-reasoning"))

(define memory-manager
  (create-membrane-node "cognition-memory"))

;; Create nesting for cognition components
(define reasoning-nesting
  (create-nesting-link "cognition-reasoning" "cognition"))

(define memory-nesting
  (create-nesting-link "cognition-memory" "cognition"))

;; Define action subsystem membranes
(define motor-control
  (create-membrane-node "action-motor"))

(define output-generator
  (create-membrane-node "action-output"))

;; Create nesting for action components
(define motor-nesting
  (create-nesting-link "action-motor" "action"))

(define output-nesting
  (create-nesting-link "action-output" "action"))

;; Define evolution rules for the cognitive system

;; Rule: Process visual input
(define visual-processing-rule
  (create-evolution-rule "perception-visual" 
                        "visual-input" 
                        "process-visual-data.sh"))

;; Rule: Process audio input
(define audio-processing-rule
  (create-evolution-rule "perception-audio"
                        "audio-input"
                        "process-audio-data.sh"))

;; Rule: Cognitive reasoning
(define reasoning-rule
  (create-evolution-rule "cognition-reasoning"
                        "reasoning-request"
                        "execute-reasoning.sh"))

;; Rule: Memory operations
(define memory-rule
  (create-evolution-rule "cognition-memory"
                        "memory-operation"
                        "handle-memory.sh"))

;; Rule: Motor actions
(define motor-rule
  (create-evolution-rule "action-motor"
                        "motor-command"
                        "execute-motor-action.sh"))

;; Define communication rules between subsystems

;; Perception -> Cognition communication
(define perception-to-cognition
  (create-communication-rule "perception" 
                            "cognition" 
                            "processed-sensory-data"))

;; Cognition -> Action communication
(define cognition-to-action
  (create-communication-rule "cognition"
                            "action"
                            "action-decision"))

;; Action -> Perception feedback loop
(define action-to-perception
  (create-communication-rule "action"
                            "perception"
                            "action-feedback"))

;; Memory <-> Reasoning bidirectional communication
(define reasoning-to-memory
  (create-communication-rule "cognition-reasoning"
                            "cognition-memory"
                            "memory-query"))

(define memory-to-reasoning
  (create-communication-rule "cognition-memory"
                            "cognition-reasoning"
                            "memory-result"))

;; Function to display the complete cognitive architecture
(define (display-cognitive-architecture)
  (display "=== Cognitive P-System Architecture ===\n")
  (display "Root Membrane: ")
  (display cognitive-root)
  (newline)
  
  (display "\nSubsystem Membranes:\n")
  (display "  Perception: ") (display perception-membrane) (newline)
  (display "  Cognition: ") (display cognition-membrane) (newline)  
  (display "  Action: ") (display action-membrane) (newline)
  
  (display "\nWorker Membranes:\n")
  (display "  Visual Processing: ") (display visual-worker) (newline)
  (display "  Audio Processing: ") (display audio-worker) (newline)
  (display "  Reasoning Engine: ") (display reasoning-engine) (newline)
  (display "  Memory Manager: ") (display memory-manager) (newline)
  (display "  Motor Control: ") (display motor-control) (newline)
  (display "  Output Generator: ") (display output-generator) (newline)
  
  (display "\nNesting Relationships:\n")
  (display "  ") (display perception-nesting) (newline)
  (display "  ") (display cognition-nesting) (newline)
  (display "  ") (display action-nesting) (newline)
  (display "  ") (display visual-nesting) (newline)
  (display "  ") (display audio-nesting) (newline)
  (display "  ") (display reasoning-nesting) (newline)
  (display "  ") (display memory-nesting) (newline)
  (display "  ") (display motor-nesting) (newline)
  (display "  ") (display output-nesting) (newline)
  
  (display "\nCommunication Rules:\n")
  (display "  ") (display perception-to-cognition) (newline)
  (display "  ") (display cognition-to-action) (newline)
  (display "  ") (display action-to-perception) (newline)
  (display "  ") (display reasoning-to-memory) (newline)
  (display "  ") (display memory-to-reasoning) (newline)
  
  (display "\nEvolution Rules:\n")
  (display "  ") (display visual-processing-rule) (newline)
  (display "  ") (display audio-processing-rule) (newline)
  (display "  ") (display reasoning-rule) (newline)
  (display "  ") (display memory-rule) (newline)
  (display "  ") (display motor-rule) (newline))

;; Function to export the architecture to JSON for orchestrator
(define (export-architecture-json)
  (display "{\n")
  (display "  \"name\": \"Cognitive P-System from Scheme\",\n")
  (display "  \"generated_by\": \"scheme-hypergraph\",\n")
  (display "  \"timestamp\": \"") (display (current-time)) (display "\",\n")
  (display "  \"membranes\": [\n")
  (display "    {\"id\": \"cognitive-root\", \"parent\": null},\n")
  (display "    {\"id\": \"perception\", \"parent\": \"cognitive-root\"},\n")
  (display "    {\"id\": \"cognition\", \"parent\": \"cognitive-root\"},\n")
  (display "    {\"id\": \"action\", \"parent\": \"cognitive-root\"},\n")
  (display "    {\"id\": \"perception-visual\", \"parent\": \"perception\"},\n")
  (display "    {\"id\": \"perception-audio\", \"parent\": \"perception\"},\n")
  (display "    {\"id\": \"cognition-reasoning\", \"parent\": \"cognition\"},\n")
  (display "    {\"id\": \"cognition-memory\", \"parent\": \"cognition\"},\n")
  (display "    {\"id\": \"action-motor\", \"parent\": \"action\"},\n")
  (display "    {\"id\": \"action-output\", \"parent\": \"action\"}\n")
  (display "  ]\n")
  (display "}\n"))

;; Display the complete architecture
(display-cognitive-architecture)

(display "\n=== P-System Cognitive Architecture Loaded ===\n")
(display "Use (display-cognitive-architecture) to show the complete structure\n")
(display "Use (export-architecture-json) to generate JSON configuration\n")