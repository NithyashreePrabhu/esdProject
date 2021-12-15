## Human Assist Multi Purpose Robot

### Features
- Autonomous multi purpose robot 
- Exploration of wifi based tracking and indoor localization
- High-end processor Raspberry PI for wifi and localization
- Low-end mbed MCU for differential drive control and obstacle detection
- Manual Control over Bluetooth

```markdown
Code block 
```

### Components used 
-


### Block Diagram
![image](https://user-images.githubusercontent.com/95492932/146130792-c3e739e7-8b3e-43fa-a178-de00e06122d2.png)

### Wi-Fi Intensity based localization
-

### Mbed Code

```markdown
Code block 
```

### Raspberry Pi Wifi Signal Capture Code

```markdown
#!/bin/bash
dummy=0
sum1=0
movingAverage1=0
count=0
skipCount=0
declare -a window1

window1[0]=0
window1[1]=0
window1[2]=0
window1[3]=0
window1[4]=0
window1[5]=0
window1[6]=0
window1[7]=0

avgMovingAvg=0
avgSkipCount=0
#python3 picam.py &

while true
do
dev1=`iw wlan0 scan | egrep 'SSID|signal' | egrep -B1 "Redmi" | grep "signal" | grep -Eo '[0-9]+([.][0-9]+)?'`

dev1Num=$(awk '{print $1+$2}' <<<"${dev1} ${dummy}")

sum1=$(expr $sum1 - ${window1[count]})

window1[count]=$dev1Num;

sum1=$(expr $sum1 + ${window1[count]})

skipCount=$(expr $skipCount + 1)
count=$(expr $count + 1)
count=$(expr $count % 3)

movingAverage1=$(expr $sum1 / 3)

if [[ $skipCount -gt 10 ]]
then

        avgMovingAvg=$(expr $movingAverage1 + $avgMovingAvg)
        avgSkipCount=$(expr $avgSkipCount + 1)
        if [ $(( $avgSkipCount % 3 )) -eq 0 ]
        then
                avgMovingAvg=$(expr $avgMovingAvg / 3)
                echo "$avgMovingAvg" >> /dev/ttyACM0
				# Store in Log file for debugging 
                echo "$avgMovingAvg" >> /home/pi/data.txt
                avgMovingAvg=0
        fi
fi

#sleep 0.1
done
```

### Raspberry Pi Camera Web streaming Code
```markdown
# Web streaming example
# Source code from the official PiCamera package
# http://picamera.readthedocs.io/en/latest/recipes2.html#web-streaming

import io
import picamera
import logging
import socketserver
from threading import Condition
from http import server

PAGE="""\
<html>
<head>
<title>Rescue Bot</title>
</head>
<body>
<center><h1>Rescue Bot</h1></center>
<center><img src="stream.mjpg" width="640" height="480"></center>
</body>
</html>
"""

class StreamingOutput(object):
    def __init__(self):
        self.frame = None
        self.buffer = io.BytesIO()
        self.condition = Condition()

    def write(self, buf):
        if buf.startswith(b'\xff\xd8'):
            # New frame, copy the existing buffer's content and notify all
            # clients it's available
            self.buffer.truncate()
            with self.condition:
                self.frame = self.buffer.getvalue()
                self.condition.notify_all()
            self.buffer.seek(0)
        return self.buffer.write(buf)

class StreamingHandler(server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(301)
            self.send_header('Location', '/index.html')
            self.end_headers()
        elif self.path == '/index.html':
            content = PAGE.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/stream.mjpg':
            self.send_response(200)
            self.send_header('Age', 0)
            self.send_header('Cache-Control', 'no-cache, private')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=FRAME')
            self.end_headers()
            try:
                while True:
                    with output.condition:
                        output.condition.wait()
                        frame = output.frame
                    self.wfile.write(b'--FRAME\r\n')
                    self.send_header('Content-Type', 'image/jpeg')
                    self.send_header('Content-Length', len(frame))
                    self.end_headers()
                    self.wfile.write(frame)
                    self.wfile.write(b'\r\n')
            except Exception as e:
                logging.warning(
                    'Removed streaming client %s: %s',
                    self.client_address, str(e))
        else:
            self.send_error(404)
            self.end_headers()

class StreamingServer(socketserver.ThreadingMixIn, server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True

with picamera.PiCamera(resolution='640x480', framerate=24) as camera:
    output = StreamingOutput()
    camera.rotation = 180
    camera.start_recording(output, format='mjpeg')
    try:
        address = ('', 8000)
        server = StreamingServer(address, StreamingHandler)
        server.serve_forever()
    finally:
        camera.stop_recording()

```

### Future Improvements


### Team Members
- Himanshu Chaudhary
- Santhana Bharathi Narasimmachari
- Dhruva Barfiwala
- Nithyashree Prabhu
