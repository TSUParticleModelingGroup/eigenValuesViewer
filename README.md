This code uses 2X2 matrices as dynamical systems to help student get a visual understanding of eigenvalues. Goes along with a paper we wrote for the ICTCM confernce.
To compile the code type
nvcc EigenValueViewerICTCM.cu -o temp -lglut -lm -lGLU -lGL
In the comand window where the code resides.
Type h for a help menu.
Select your matrix or enter a matrix of your choice.
Left cleck in the window to select a starting point then right click to generate the next point in the sequence.
