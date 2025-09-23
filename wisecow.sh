#!/usr/bin/env bash

SRVPORT=4499
RSPFILE=response

rm -f $RSPFILE
mkfifo $RSPFILE

get_api() {
    read line
    echo $line
}

handleRequest() {
    # 1) Process the request
    get_api
    mod=$(fortune)

cat <<EOF > $RSPFILE
HTTP/1.1 200 OK
Content-Type: text/html

# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="UTF-8">
#     <title>DevOps Trainee Role</title>
#     <style>
#     body {
#         font-family: Arial, sans-serif;
#         background-color: #f4f7fa;
#         margin: 0;
#         padding: 0;
#     }
#     header {
#         background-color: #e53935; /* Changed from blue to red */
#         color: white;
#         padding: 20px;
#         text-align: center;
    
#     }
#     .fortune {
#         background-color: #ffebee; /* Changed from blue to light red */
#         padding: 15px;
#         font-family: monospace;
#         white-space: pre;
#         border: 1px solid #ffccd5; /* Changed from blue to a soft red */
#         margin: 20px;
#     }
#     .section {
#         margin: 20px;
#         padding: 20px;
#         border-radius: 8px
#         ;

#     }
#     h2 {
#         color: #333;
#         left-margin: 100px;
#     }

# </style>

# </head>
# <body>
#     <header>
#         <h1>AccuKnox Assignment</h1>
#     </header>

#     <div class="fortune">
# $(cowsay "$mod")
#     </div>
#         <div class="section">
#         <h2>Submission by Om Harsule</h2>
#     </div>
# </body>
# </html>
EOF
}

prerequisites() {
    command -v cowsay >/dev/null 2>&1 &&
    command -v fortune >/dev/null 2>&1 ||
        {
            echo "Install prerequisites: cowsay, fortune"
            exit 1
        }
}

main() {
    prerequisites
    echo "Wisdom served on port=$SRVPORT..."

    while true; do
        cat $RSPFILE | nc -l $SRVPORT | handleRequest
        sleep 0.01
    done
}

main
