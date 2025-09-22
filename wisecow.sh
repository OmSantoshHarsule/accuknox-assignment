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

    HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Accuknox Problem Statement</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f7fa;
            margin: 0;
            padding: 0;
        }
        header {
            background-color: #4a90e2;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .signature {
            background-color: #fff;
            padding: 10px;
            text-align: center;
            font-weight: bold;
        }
        .fortune {
            background-color: #e6f7ff;
            padding: 15px;
            font-family: monospace;
            white-space: pre;
            border: 1px solid #cce7ff;
            margin: 20px;
        }
        .section {
            margin: 20px;
            padding: 20px;
            border-radius: 8px;
        }
        .section:nth-child(even) {
            background-color: #ffffff;
        }
        .section:nth-child(odd) {
            background-color: #f0f0f5;
        }
        h2 {
            color: #333;
        }
        .question {
            font-weight: bold;
            color: #1a237e;
        }
        .answer {
            margin-top: 5px;
            color: #2e7d32;
        }
    </style>
</head>
<body>
    # <header>
    #     <h1>Kubernetes Questions & Answers</h1>
    # </header>

    <div class="signature">
        Submission by Om Harsule
    </div>

    <div class="fortune">
$(cowsay "$mod")
    </div>

    # <div class="section">
    #     <h2>Question 1</h2>
    #     <div class="question">What is a Pod in Kubernetes?</div>
    #     <div class="answer">A Pod is the smallest deployable unit in Kubernetes that can contain one or more containers sharing the same network and storage.</div>
    # </div>

    # <div class="section">
    #     <h2>Question 2</h2>
    #     <div class="question">What is the difference between Deployment and StatefulSet?</div>
    #     <div class="answer">Deployment manages stateless applications, while StatefulSet is used for stateful apps where each pod has a persistent identity and stable storage.</div>
    # </div>

    # <div class="section">
    #     <h2>Question 3</h2>
    #     <div class="question">How does Kubernetes handle service discovery?</div>
    #     <div class="answer">Kubernetes uses kube-dns or CoreDNS to map service names to IP addresses and enables discovery across clusters.</div>
    # </div>

    # <div class="section">
    #     <h2>Question 4</h2>
    #     <div class="question">What are ConfigMaps and Secrets?</div>
    #     <div class="answer">ConfigMaps hold non-sensitive config data, while Secrets store sensitive information like passwords and tokens in base64 encoded format.</div>
    # </div>

</body>
</html>
EOF
}
    
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
