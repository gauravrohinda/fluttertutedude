# Task 7 - Dice Roller App 🎲

This is a very simple and fun Flutter app that acts like a real dice! You can use it to play games like Ludo, Snakes & Ladders, or just for fun.

## How it works (In Simple Words)

1. **The Dice Screen**: When you open the app, you will see a dice on the screen showing a number from 1 to 6.
2. **The Magic Button**: At the bottom, there is a big button that says "Roll the Dice".
3. **What happens when you press it?**: 
   - The app instantly picks a random number between 1 and 6 (just like throwing a real dice).
   - It updates the screen to show the new dice face.
   - We built the dice using code instead of downloading images, so the app is super fast and will never crash!

## App Screenshot
![App Screenshot](screenshot.png)

*(Note: Just put a picture named `screenshot.png` in this folder, and it will show up right here!)*

## Technical Stuff
- Built using **StatefulWidget** to remember the dice number.
- Uses **setState()** to refresh the screen when the number changes.
- Uses **CustomPaint** to draw a beautiful dice without needing any external image files.
