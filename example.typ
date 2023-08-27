#import "typst-notebook.typ": notebook-render

= Introduction to Typst Notebook

== Code and result
#notebook-render(
```python
from matplotlib import pyplot as plt
import numpy as np

# Generate 100 random data points along 3 dimensions
x, y, scale = np.random.randn(3, 100)
fig, ax = plt.subplots()

# Map each onto a scatterplot we'll create with Matplotlib
ax.scatter(x=x, y=y, c=scale, s=np.abs(scale)*500)
ax.set(title="Some random data, created with Typst!")
plt.show()
```)

== Only display result
Initialize a string
#notebook-render(```python
string = "Hello "
```)
Add a name
#notebook-render(```python
string += "typst"
```)
Output the string
#notebook-render(```python
display(string)
```)