#!/usr/bin/env bash

SRVPORT=4499

prerequisites() {
    command -v cowsay >/dev/null 2>&1 &&
    command -v fortune >/dev/null 2>&1 &&
    command -v socat >/dev/null 2>&1 || { 
        echo "Install prerequisites: cowsay, fortune, and socat."
        exit 1
    }
}

# Function to generate HTTP response
generate_response() {
    local fortune_text cow_text html_content
    
    fortune_text=$(fortune)
    cow_text=$(cowsay "$fortune_text")
    html_content="<pre>$cow_text</pre>"
    
    # HTTP response with proper headers
    cat <<EOF
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: ${#html_content}
Connection: close

$html_content
EOF
}

handleRequest() {
    echo "Starting Wisecow server on port $SRVPORT with socat..."
    
    # Use socat to create a proper HTTP server
    while true; do
        echo "Listening for connections..."
        socat TCP-LISTEN:$SRVPORT,reuseaddr,fork EXEC:"bash -c 'generate_response'" &
        SOCAT_PID=$!
        
        # Wait for socat to start
        sleep 1
        
        # Check if socat is running
        if kill -0 $SOCAT_PID 2>/dev/null; then
            echo "Server started successfully with PID $SOCAT_PID"
            wait $SOCAT_PID
        else
            echo "Failed to start server, retrying..."
            sleep 2
        fi
    done
}

main() {
    prerequisites
    
    # Export the function so socat can use it
    export -f generate_response
    
    echo "Wisdom served on port=$SRVPORT..."
    handleRequest
}

# Handle cleanup
cleanup() {
    echo "Shutting down Wisecow server..."
    pkill -f "socat.*$SRVPORT" 2>/dev/null
    exit 0
}

trap cleanup SIGTERM SIGINT

main