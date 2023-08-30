#import "typst-notebook.typ": *

//#notebook-add-mimetype-handler("application/vnd.vegalite.v3+json", repr)

= Introduction to Typst Notebook
== Code and result
#notebook("python")[
    #set image(width: 35%)
    #notebook-cell(
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
        ```
    )
]

== Split in multiple parts
#notebook("python")[
    Initialize a string
    #notebook-cell(```python
    string = "Hello "
    ```)
    Add a name
    #notebook-cell(```python
    string += "typst"
    ```)
    Output the string
    #notebook-cell(```python
    display(string)
    ```)
]

== Using other kernels is also supported
#notebook("xsqlite")[
    #notebook-cell(```sql
    %CREATE example_db.db
    ```)
    #notebook-cell(```sql
    CREATE TABLE players (Name STRING, Class STRING, Level INTEGER, Hitpoints INTEGER)
    ```)
    #notebook-cell(```sql
    INSERT INTO players (Name, Class, Level, Hitpoints) VALUES ("Martin Splitskull", "Warrior", 3, 40)
    ```)
    #notebook-cell(```sql
    INSERT INTO players (Name, Class, Level, Hitpoints) VALUES ("Sir Wolf", "Cleric", 2, 20);
    ```)
    #notebook-cell(```sql
    SELECT Name, Level, Hitpoints FROM players;
    ```)
    #notebook-cell(```sql
    INSERT INTO players (Name, Class, Level, Hitpoints) VALUES ("Sylvain, The Grey", "Wizard", 1, 10);
    ```)
    #notebook-cell(```sql
    %XVEGA_PLOT
        X_FIELD Level
        Y_FIELD Hitpoints
        MARK circle
        WIDTH 100
        HEIGHT 200
        <>
        SELECT Level, Hitpoints FROM players
    ```)
]