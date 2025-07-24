#!/bin/bash
# Process visual data evolution rule
# Triggered when visual input is received by perception-visual membrane

set -e

INPUT_DATA="$1"
MEMBRANE_ID="perception-visual"

echo "Visual processing rule activated in membrane: $MEMBRANE_ID"
echo "Processing input: $INPUT_DATA"

# Simulate visual processing
if [[ "$INPUT_DATA" == *"image"* ]]; then
    echo "Detected image data - performing object recognition"
    
    # Create processed output
    OUTPUT_FILE="/opt/membrane/state/visual_processed_$(date +%s).json"
    cat > "$OUTPUT_FILE" << EOF
{
  "type": "visual_processing_result",
  "input": "$INPUT_DATA",
  "processing_time": "$(date -Iseconds)",
  "membrane": "$MEMBRANE_ID",
  "results": {
    "objects_detected": ["object1", "object2"],
    "confidence": 0.85,
    "processing_method": "simulated_recognition"
  }
}
EOF

    # Send result to cognition membrane
    if command -v membrane >/dev/null 2>&1; then
        membrane send cognition "visual-processing-complete:$OUTPUT_FILE"
    fi
    
    echo "Visual processing complete - results sent to cognition"
    
elif [[ "$INPUT_DATA" == *"video"* ]]; then
    echo "Detected video data - performing motion analysis"
    
    # Create motion analysis output
    OUTPUT_FILE="/opt/membrane/state/motion_analysis_$(date +%s).json"
    cat > "$OUTPUT_FILE" << EOF
{
  "type": "motion_analysis_result", 
  "input": "$INPUT_DATA",
  "processing_time": "$(date -Iseconds)",
  "membrane": "$MEMBRANE_ID",
  "results": {
    "motion_vectors": [[1,2], [3,4], [5,6]],
    "tracking_objects": 3,
    "analysis_method": "simulated_tracking"
  }
}
EOF

    # Send result to cognition membrane
    if command -v membrane >/dev/null 2>&1; then
        membrane send cognition "motion-analysis-complete:$OUTPUT_FILE"
    fi
    
    echo "Motion analysis complete - results sent to cognition"
    
else
    echo "Unknown visual input type - performing generic processing"
    
    # Generic visual processing
    OUTPUT_FILE="/opt/membrane/state/generic_visual_$(date +%s).json"
    cat > "$OUTPUT_FILE" << EOF
{
  "type": "generic_visual_result",
  "input": "$INPUT_DATA", 
  "processing_time": "$(date -Iseconds)",
  "membrane": "$MEMBRANE_ID",
  "results": {
    "processed": true,
    "method": "generic_visual_processing"
  }
}
EOF

    # Send result to cognition membrane
    if command -v membrane >/dev/null 2>&1; then
        membrane send cognition "visual-generic-complete:$OUTPUT_FILE"
    fi
    
    echo "Generic visual processing complete"
fi

# Log the evolution rule execution
if [ -f "/opt/membrane/logs/events.log" ]; then
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"membrane\": \"$MEMBRANE_ID\", \"event\": \"evolution_rule_executed\", \"rule\": \"process-visual-data\", \"input\": \"$INPUT_DATA\"}" >> /opt/membrane/logs/events.log
fi

echo "Visual processing evolution rule completed"