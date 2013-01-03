#skybot
NOTICE: This project is still under development

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
ruby skybot/bot.sh
```

##License
MIT
