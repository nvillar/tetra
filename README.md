# tetra
**tetra** is a script for monome norns and grid.

Use the grid to create and interact with sound objects called tetras.  
Each tetra makes a sound that can be played manually or sequentially.  
Sequences are created from groups of adjacent tetras.

## Tetras

Tetras are formed on the grid by four adjacent keys, excluding diagonals.  
There are 7 possible shapes (think tetris): I, O, T, L, J, S, Z.  
Some shapes have two or four possible orientations.  

When a tetra is completed, it starts to act as a single entity.  
Pressing any one of its keys will activate it and trigger a sound.  
The sound is determined by the shape of the tetra, and, in some cases, by its orientation.  
The note played by the tetra is chosen randomly from a scale, which can be changed from the parameters menu.  

There are three possible adjustments to the sound of a tetra: note, timbre, and volume, which can be changed by  
selecting a tetra and turning the encoders on the norns. The last tetra to be pressed will remain selected.  
The adjustments are saved with each tetra, and will be used whenever the tetra is activated.  
New tetras of that shape will inherit the timbre and volume adjustments as the last one to be edited.  
If a tetra is pressed while turning the encoders, the sound will be played with each turn of the encoder.  

To move a tetra, press and hold a key on it, and then press another key at the destination.  
Tetras can not overlap, or go outside the bounds of the grid.   
Any lit keys, which are not part of a tetra, will also prevent a tetra from moving to that position.  

To delete a tetra, press and hold **three** of its keys.  
To delete all tetras, press and hold any two diagonally opposite corner-keys on the grid.

## Groups

A groups is created when two or more tetras are adjacent to each other by at least one key.  
Tetras in a group is played sequentially, in the order they were added to the group.  
The last tetra to be added will play after all the other tetras in the group.  
If a tetra adjoins two or more exisiting sequences, the sequences are merged into one.  
If deleting or moving a tetra splits a group, new groups are created from the remaining tetras.  

The rate at which the sequence is played can be adjusted from the parameters clock menu.  
The the left key on the norns will stop the sequence, and the right key will start it.  

## Installation

Install via maiden or manually by copying the folder to the norns code directory.  
Restart after installing to enable the synth engine.

# Requirements

- monome norns or norns shield
- monome grid or compatible device (any size should work,
but have only been tested with 128 grid)

## Thank you

Thank you the monome community, especially @tehn, @dndrks for the study material, and  
@tyleretters for the nornsilerplate and video tutorial.   
The Pond engine used in this script is a stripped out version of @williamthazard's LiedMotor engine.

https://github.com/monome/norns

https://github.com/northern-information/nornsilerplate

https://github.com/williamthazard/schicksalslied







