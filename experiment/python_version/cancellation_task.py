from psychopy import visual, core
from psychopy.hardware import keyboard

win = visual.Window()
welcome_text = visual.TextStim(win, text = "Welcome to the cancellation task!", autoDraw=True)

win.flip()
core.wait(2.0)

