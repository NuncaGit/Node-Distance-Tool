Node Distance Tool for Godot

The Node Distance Tool is an addon that simplifies measuring distances between 3D nodes directly in the Godot editor. Using it, you can select two nodes with the Q key and measure the distance between them, displaying the values directly in the scene and console.

How It Works
Quick Selection with "Q": Select a node with the mouse and press Q to register it. Then, select another node and press Q again to measure the distance between them. The distance will be displayed in the scene and the console (print_rich).

[Space for GIF: Example of a simple measurement using "Q", showing the distance in the console]

Measurement Modes
This addon has three distinct modes for measurement:

Normal Mode: Select two nodes with "Q" to measure the distance. It creates a line connecting the nodes and displays a label with the rounded distance. After measuring two nodes, you need to select two more for the next measurement. Ideal for direct, precise measurements, with all calculations displayed in the console.

Continuos Mode: After measuring two nodes, the next selected node will automatically be measured in relation to the previous one. This allows for continuous sequences of measurements without resetting.

Togheter Mode: Select multiple nodes with "Q", and when any of them move, the distance between all nodes is recalculated and displayed. Previous lines and labels are updated to reflect the new distances. All calculations are displayed in the console.

Control Panel
In the 3D editor, there is a control panel located in the CONTAINER_SPATIAL_EDITOR_MENU (PainelMetragem) that facilitates activating the modes and visualizing measurements. The buttons include:

Reset: Removes all measurements from the scene.
Show/Hide Lines and Labels: Toggles the display of lines and labels.
Continuos and Togheter Modes: Activates or deactivates these modes directly from the panel.