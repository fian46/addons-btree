# **Welcome to the addons-btree wiki!**
Warning : is this the best way ? No. Nothing is perfect. This plugin was designed for my own game, I wanted to make it simple and threw programming's best practices out the window. It may have some flaws, but for my case it was perfect. Try it for 15 minutes and if you don't think it fits your use case, no harm done, don't waste your time. Otherwise, I hope you enjoy the plugin!

## 1. Installation
Clone or download the addons folder and add it in your project. <br/>
**OR** <br/>
Download the plugin via the [Godot Asset Library](https://godotengine.org/asset-library/asset/725):

![files](https://user-images.githubusercontent.com/13792627/70871831-8014b000-1fe6-11ea-9cce-1567ac182da7.png) </br>

Then activate the plugin in your Project Settings.

![setting](https://user-images.githubusercontent.com/13792627/70871854-bbaf7a00-1fe6-11ea-9892-4252e90f2ab1.png)
## 2. Concept
* It is a behavior tree just like any other, no magic here, if you need to learn the concept, a quick google search will get you a long way.
* The addon works with only a single script, you can however combine multiple BTree's in one parent. For example, you can separate your animation tree from your logic tree.

![mtree](https://user-images.githubusercontent.com/13792627/70871940-63c54300-1fe7-11ea-9f53-676c5f893423.png)
## 3. How to use BTREE
* You can add BTREE as a child to any node. You must add a script to the BTree or the plugin will error!

![create](https://user-images.githubusercontent.com/13792627/70872028-52c90180-1fe8-11ea-80bc-b39dc606cb62.png)
* Select the BTREE node and switch to the BTree Editor (BTEditor) window in the top menu.

![5](https://user-images.githubusercontent.com/13792627/70872090-c10dc400-1fe8-11ea-8213-fe517ce4b4ff.png)
* You will need a node to connect to the root or it will not run.
* To create a task / leaf node, you will need to make a function that follows this naming scheme: `task_<methodname>(task)`. For example, a function that prints "hello world" can have the name `task_printhelloworld(task)`.
* The function must also have the argument `task`. This argument is used for flow control.
* You can call functions on this argument. You can call `succeed()` to complete the task on success or `failed()` to complete on failure. The task status keeps running if you do not call anything, that means in the next tick it will be called again until you call `succeed()` or `failed()`. To determine if a task is initialized or not you can call `is_init()` in the control flow. If it returns true then the node is initialized, this is useful for a task that requires something to be initialized before running, for example, computing a path.

![6](https://user-images.githubusercontent.com/13792627/70872235-e949f280-1fe9-11ea-8f5b-67c9a7834b4c.png)

![7](https://user-images.githubusercontent.com/13792627/70872236-ecdd7980-1fe9-11ea-9da8-b0268c318b25.png)

* You can also pass your owns arguments to the task from the Tree Editor. This is for example useful when creating some kind of dialogue system for NPCs or to play an animation.

![8](https://user-images.githubusercontent.com/13792627/70872323-958bd900-1fea-11ea-931c-2bc5f400c58f.png)

![9](https://user-images.githubusercontent.com/13792627/70872347-cbc95880-1fea-11ea-8482-ba94b1a3a28f.png)

* You can look up the rest of the node behavior by hovering your mouse which displays a  tool tip you can use. The is also a help button that explains some basic controls like copying, deleting and saving nodes etc..

## 4. Debugger
* You can visualize the current running BTree instance in your game by clicking the debug button, your game must be running or debugger will not show anything.
* Currently you can only see the status but if you need anything more advanced or fancy, feel free to create an issue.
  ![d1](https://user-images.githubusercontent.com/13792627/93017110-b1afbb80-f5f8-11ea-8c23-c07525fd1a19.png)
  ![d2](https://user-images.githubusercontent.com/13792627/93017112-b2e0e880-f5f8-11ea-93d6-a3826869f878.png)
* The Debugger will currently does not work on mobile, only local desktop machine is supported.
* You can pause a BTree while debugging by pressing pause.
* You can step a BTree while it is paused by pressing and holding the step button.
* To perform a hot reload go to the BTEditor while your project is running, perform your changes and afterwards after press save or **CTRL + S**, this will update your whole project, not only the running tree but also the same tree after it gets instanced.

## 5. Tutorial
* The tutorial is credited to this Youtube channel  [Vic Ben](https://www.youtube.com/channel/UCKfmrrk5hcgKiPHKN6mi4HA)
* This is a great tutorial on how to use the plugins [Video Link](https://youtu.be/HEnKCJ9AQ9E)
* Again I have to thank Vic Ben for making these tutorial videos.