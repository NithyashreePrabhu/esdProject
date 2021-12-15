## Rescue and Human Assist Multi Purpose Robot

### Features
- Autonomous multi purpose robot 
- Exploration of wifi based tracking and indoor localization
- High-end processor Raspberry PI for wifi and localization
- Low-end mbed MCU for differential drive control and obstacle detection
- Manual Control over Bluetooth


### Components used 
-


### Block Diagram
![image](https://user-images.githubusercontent.com/95492932/146130792-c3e739e7-8b3e-43fa-a178-de00e06122d2.png)

### Manual Control over BLE

- Complete manual control over BLE, operator could leverage real-time video feed over the server to perform precise tasks
 

![image](https://github.com/NithyashreePrabhu/esdProject/blob/gh-pages/Manual.PNG)


### Wi-Fi Intensity based localization and path-planning

- Serial Interface with Raspberry Pi to read the wifi strength (in decibels) of the source using an interrupt mechanism

- Iterative path-planning algorithm: The algorithm iteratively move towards the source location based on real-time feedback of the wifi strength.

![image](https://github.com/NithyashreePrabhu/esdProject/blob/gh-pages/Flow.png)


### Mbed Code

```markdown
#include "mbed.h"
#include "Motor.h"

Motor right(p23, p6, p5); // pwm, fwd, rev
Motor left(p24, p8, p7); // pwm, fwd, rev
Serial Blue(p13,p14); // BLE control
Serial  pi(USBTX, USBRX); // Communication with RPi 
DigitalOut led1(LED1); // Data receive indicator in auto mode

//global variables for main and interrupt routine
float robo_speed = 0.5;
float right_robo_speed = 0.6;
volatile bool auto_mode = false;
volatile bool button_ready = 0;
volatile int  bnum = 0;
volatile int  bhit  ;
volatile int s1_intensity = 0, s1_intensity_prev = 0;
volatile bool dir_change = false;
volatile int count = 0;
volatile char  temp[4] = {0 , 0, 0, 0};
//state used to remember previous characters read in a button message
enum statetype {start = 0, got_exclm, got_B, got_num, got_hit};
statetype state = start;


//Interrupt routine to parse message with one new character per serial RX interrupt
void parse_message()
{
    switch (state) {
        case start:
            if (Blue.getc()=='!') state = got_exclm;
            else state = start;
            break;
        case got_exclm:
            if (Blue.getc() == 'B') state = got_B;
            else state = start;
            break;
        case got_B:
            bnum = Blue.getc();
            state = got_num;
            break;
        case got_num:
            bhit = Blue.getc();
            state = got_hit;
            break;
        case got_hit:
            if (Blue.getc() == char(~('!' + ' B' + bnum + bhit))) button_ready = 1;
            state = start;
            break;
        default:
            Blue.getc();
            state = start;
    }
}

//
// Move back
//
void m_reverse(void)
{
    left.speed(robo_speed);
    right.speed(robo_speed);
}

//
// Move forward
// Slight change in left and right speeds to compensate
// for the wheel drift on test terrain
//
void m_forward(void)
{
    left.speed((-1.0 * robo_speed) + 0.02);
    right.speed((-1.0 * robo_speed) - 0.02);
}

//
// Move left
//
void m_left(void)
{
    left.speed(robo_speed);
    right.speed(-1.0 * robo_speed);
}

//
// Move right
//
void m_right(void)
{
    right.speed(right_robo_speed);
    left.speed(-1.0 * right_robo_speed);
}

//
// Stop both wheels
//
void stop(void)
{
    right.speed(0.0);
    left.speed(0.0);
}

//
// Serial Interrupt for Raspberry Pi communication
//
void dev_recv()
{
    
  temp[count++] = pi.getc();
  temp[count++] = pi.getc();
  temp[count++] = pi.getc();
  temp[count++] = pi.getc();
  
  if ( count == 4)
  {
       count = 0;
       s1_intensity = ((int)temp[0] - '0') * 10 + ((int)temp[1] - '0');  
  } 
         
  if(auto_mode && (!dir_change))
  {
      led1 = !led1;
            
      if (s1_intensity < 40)
      {
          stop();    
          auto_mode = false;
          state = start;
      }
      else if(s1_intensity > (s1_intensity_prev + 5))
      {
          m_right();   
          wait(0.6);
          m_forward();
          wait(3.0);
          stop();
          s1_intensity_prev = s1_intensity;
      }
      else if (s1_intensity > 65)
      {
          m_right();   
          wait(1.0);
          m_forward();
          wait(4.0);
          stop();                
      }
      else
      {
          m_forward();
          wait(2);
          stop();
      }
          
  }
}


int main()
{
     Blue.attach(&parse_message,Serial::RxIrq);
     pi.baud(9600);
     pi.attach(&dev_recv, Serial::RxIrq);
     
    while(1) {
        if (button_ready) 
        {                          
           if(bnum == '7')
              auto_mode = true;
           else if (bnum == '8')
              auto_mode = false;
           else{}
                    
           if(!auto_mode)
           {
                        switch (bnum) {
                            case '1': //number button 1
                                if (bhit=='1') {
                                    m_forward();
                                } else {
                                    //add release code here
                                    stop();
                                }
                                break;
                            case '2': //number button 2
                                if (bhit=='1') {
                                    m_reverse();
                                } else {
                                    stop();
                                }
                                break;
                            case '3': //number button 3
                                if (bhit=='1') {
                                    m_left();
                                } else {
                                    stop();
                                }
                                break;
                            case '4': //number button 4
                                if (bhit=='1') {
                                    m_right();
                                } else {
                                    stop();
                                }
                                break;
                            case '5': //button 5 up arrow
                                if (bhit=='1') {
                                    robo_speed += 0.05;
                                } else {
                                    
                                }
                                break;
                            case '6': //button 6 down arrow
                                if (bhit=='1') {
                                    robo_speed -= 0.05;
                                } else {
                                    
                                }
                                break;                            
                            default:
                                break;
                        }
                    }       
                }      
                
        
        wait(0.1);
    }
}

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

- Multi-source wifi triangulation for indoor mapping
- Live firmware upgrade for the mbed using Ethernet connectivity on Rasberry Pi


### Team Members
- Himanshu Chaudhary
- Santhana Bharathi Narasimmachari
- Dhruva Barfiwala
- Nithyashree Prabhu
