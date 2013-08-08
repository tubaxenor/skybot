#skybot
NOTICE: This project is dead, because skype will no longer support desktop API ...

http://gigaom.com/2013/07/13/skype-says-it-will-kill-desktop-api-by-end-of-2013/

##Installation

* You need to be on Linux
* You need to have Skype running
* You need dbus installed (e.g., via apt on Ubuntu)

and, finally
```
bundle install
```

##Usage
```
ruby bot.rb
```

##Headless running in Ubuntu

Make sure you have skype, xvfb, fluxbox, and x11vnc installed :
```
sudo apt-get install xvfb fluxbox x11vnc skype
```

Open ssh tunnel for VNC :
```
ssh -L 5900:localhost:5900 youraccount@yourserver.com
```

Get the bot (on server):
```
git clone https://github.com/tubaxenor/skybot.git
```

Run skype, xvfb, fluxbox, and x11vnc (on server)
```
skybot/start-vncserver.sh
```

On local machine, start vncviewer
```
vncviewer localhost
```

After login and setting, on your server :
```
skybot start
```

##License
MIT
