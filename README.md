# 🎮 Brick Breaker in x86 Assembly Language

A classic **Brick Breaker (Breakout)** game developed entirely in **16-bit x86 Assembly Language (NASM)** for DOS using **VGA Mode 13h** graphics.

This project demonstrates how an entire game can be built from scratch without using any game engine or graphics library. Everything—from graphics rendering and collision detection to keyboard input, sound effects, and file handling—is implemented directly using low-level Assembly programming and DOS interrupts.

---

## 📖 About the Game

Brick Breaker is one of the most iconic arcade games.

The objective is simple:

* Control the paddle at the bottom of the screen.
* Bounce the ball using the paddle.
* Destroy all the bricks.
* Prevent the ball from falling below the paddle.
* Complete all levels while achieving the highest possible score.

As the player progresses, the game increases in difficulty, making each level more challenging.

---

# ✨ Features

✅ Welcome Screen

✅ Multiple Brick Types

✅ Color-based Brick Scoring

✅ Real-time Paddle Movement

✅ Ball Physics

✅ Wall Collision Detection

✅ Paddle Collision Detection

✅ Brick Collision Detection

✅ Multiple Levels

✅ Score Counter

✅ Lives System

✅ High Score Saving

✅ Persistent High Score File

✅ PC Speaker Sound Effects

✅ Restart Game Option

✅ Game Over Screen

---

# 🖥️ Technologies Used

* **Language:** x86 Assembly Language
* **Assembler:** NASM (Netwide Assembler)
* **Platform:** DOS
* **Graphics Mode:** VGA Mode 13h (320 × 200, 256 Colors)
* **Interrupts Used:**

  * INT 10h (Video Services)
  * INT 16h (Keyboard Services)
  * INT 21h (DOS Services)

---

# 🧠 What is Assembly Language?

Assembly Language is a **low-level programming language** that provides direct access to a computer's hardware.

Unlike languages such as C++, Java, or Python, Assembly instructions correspond closely to machine instructions executed by the CPU.

Example:

```asm
mov ax, 10
add ax, 5
```

Assembly offers:

* Maximum performance
* Direct hardware interaction
* Precise memory control
* Better understanding of CPU architecture

---

# 🔹 Why NASM?

**NASM (Netwide Assembler)** is one of the most popular x86 assemblers.

It is:

* Open Source
* Lightweight
* Fast
* Easy to learn
* Cross-platform

NASM converts Assembly source code (`.asm`) into executable machine code.

Official Website:

https://www.nasm.us/

---

# 🎨 Graphics

The game uses **VGA Mode 13h**, which provides:

* Resolution: **320 × 200**
* Colors: **256**
* Video Memory Segment: **A000:0000**

Every pixel is drawn manually by writing directly into VGA memory.

---

# 🔊 Sound

Sound effects are generated using the **PC Speaker**.

Different frequencies are used for:

* Paddle Collision
* Brick Collision
* Losing a Life

---

# 🎮 Controls

| Key           | Action            |
| ------------- | ----------------- |
| ⬅ Left Arrow  | Move Paddle Left  |
| ➡ Right Arrow | Move Paddle Right |
| Enter         | Start Game        |
| Y             | Restart Game      |
| N             | Quit              |
| ESC           | Exit Game         |

---

# 🏆 Scoring System

Different brick colors award different points.

| Brick Type | Points |
| ---------- | ------ |
| Blue       | 10     |
| Green      | 20     |
| Red        | 30     |
| Yellow     | 40     |

Destroy every brick to advance to the next level.

---

# ❤️ Lives

The player starts with **3 lives**.

A life is lost whenever the ball falls below the paddle.

The game ends when all lives are exhausted.

---

# 💾 High Score

The game stores the highest score inside:

```
hiscore.dat
```

This file is automatically:

* Created (if missing)
* Updated
* Loaded when the game starts

---

# 📂 Project Structure

```
BrickBreaker/
│
├── BrickBreaker.asm
├── hiscore.dat
├── README.md
└── screenshots/
    ├── welcome.png
    ├── gameplay.png
    └── gameover.png
```

---

# 🚀 Building the Project

## 1. Install NASM

Download NASM from:

https://www.nasm.us/

Verify installation:

```bash
nasm -v
```

---

## 2. Assemble

```bash
nasm -f bin BrickBreaker.asm -o BrickBreaker.com
```

---

# ▶ Running the Game

Since this is a DOS program, it should be executed inside **DOSBox** (or another DOS emulator).

Example:

```bash
dosbox
```

Inside DOSBox:

```dos
mount c .
c:
BrickBreaker.com
```

The game will start with the welcome screen.

---

# 📸 Screenshots

Add screenshots here after running the game.

Example:

```
screenshots/
```

* Welcome Screen
* Gameplay
* Game Over Screen
* Winning Screen

---

# 📚 Concepts Demonstrated

This project covers many low-level programming concepts, including:

* Assembly Language Programming
* VGA Graphics Programming
* Direct Video Memory Access
* Keyboard Interrupts
* DOS File Handling
* Collision Detection
* Game Loop Design
* Memory Management
* PC Speaker Programming
* Modular Procedure Design

---

# 🎯 Learning Outcomes

Building this project helped strengthen my understanding of:

* Computer Organization
* Computer Architecture
* Operating Systems
* Low-Level Graphics Programming
* DOS Programming
* Hardware Interaction
* Efficient Memory Usage
* Problem Solving in Assembly Language

---

# 🔮 Possible Future Improvements

* Pause Menu
* Power-ups
* Different Paddle Sizes
* Animated Bricks
* Background Music
* Mouse Support
* More Levels
* Improved Ball Physics
* Better Collision Angles
* High Score Table
* Custom Difficulty Modes

---

# 👨‍💻 Author

**Ahmed**

BS Computer Science

FAST – National University of Computer and Emerging Sciences

---

# ⭐ Support

If you found this project interesting, consider giving it a ⭐ on GitHub.

Feedback and suggestions are always welcome!

---

# 📄 License

This project is developed for educational purposes and learning Assembly Language.
