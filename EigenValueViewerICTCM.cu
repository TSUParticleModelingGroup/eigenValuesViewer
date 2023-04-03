//nvcc EigenValueViewerICTCM.cu -o temp -lglut -lm -lGLU -lGL
//#include <GL/glut.h>
//#include <math.h>
//#include <stdio.h>
//#include <device.h>

#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <cuda.h>
using namespace std;

#define SCALE 50.0

#define X_WINDOW 1000
#define Y_WINDOW 1000

#define X_MAX SCALE
#define X_MIN -SCALE
#define X_SCALE 1.0

#define Y_MAX SCALE
#define Y_MIN -SCALE
#define Y_SCALE 1.0

FILE* ffmpeg;

// function prototypes
void KeyPressed(unsigned char key, int x, int y);
void Display(void);

//globalsgcc FunctionHit.c -o FunctionHit -lglut -lm -lGLU -lGL
double g_x;
double g_y;
static int g_win;
double A11, A12, A21, A22;
int* Buffer;

double x_machine_to_x_screen(int x)
{
	return( (2.0*x)/X_WINDOW-1.0 );
}

double y_machine_to_y_screen(int y)
{
	return( -(2.0*y)/Y_WINDOW+1.0 );
}

double x_machine_to_x_world(int x)
{
	double range;
	range = X_MAX - X_MIN;
	return( (range/X_WINDOW)*x + X_MIN);
}

double y_machine_to_y_world(int y)
{
	double range;
	range = Y_MAX - Y_MIN;
	return(-((range/Y_WINDOW)*y - X_MAX));
}

double x_world_to_x_screen(double x)
{
	double range;
	range = X_MAX - X_MIN;
	return( -1.0 + 2.0*(x - X_MIN)/range );
}

double y_world_to_y_screen(double y)
{
	double range;
	range = Y_MAX - Y_MIN;
	return( -1.0 + 2.0*(y - Y_MIN)/range );
}

void place_axis()
{
	glColor3f(1.0,1.0,1.0);

	glBegin(GL_LINE_LOOP);
		glVertex2f(x_machine_to_x_screen(0),0);
		glVertex2f(x_machine_to_x_screen(X_WINDOW),0);
	glEnd();

	glBegin(GL_LINE_LOOP);
		glVertex2f(0,y_machine_to_y_screen(0));
		glVertex2f(0,y_machine_to_y_screen(Y_WINDOW));
	glEnd();

	glFlush();
}

void placePoint(double x, double y)
{
	glPointSize(5);
	glBegin(GL_POINTS);
		glVertex2f(x_world_to_x_screen(x),y_world_to_y_screen(y));
	glEnd();
	glFlush();
}

void hitMatrix(double x, double y)
{
	double xOld = x;
	double yOld = y;
	
	g_x = A11*xOld + A12*yOld;
	g_y = A21*xOld + A22*yOld;
}

void printPoint()
{
	printf("\n  x = %f\n",g_x);
	printf("  y = %f\n",g_y);
}

void mymouse(int button, int state, int x, int y)
{	
	if(state == GLUT_DOWN)
	{
		if(button == GLUT_LEFT_BUTTON)
		{
			glColor3f(1.0,1.0,0.0);
			g_x = x_machine_to_x_world(x);
			g_y = y_machine_to_y_world(y);
			placePoint(g_x,g_y);
			printPoint();
		}
		else
		{
			glColor3f(0.0,1.0,0.0);
			hitMatrix(g_x,g_y);
			placePoint(g_x,g_y);
			printPoint();
		}
	}
}

void help()
{
	printf("\n Click in the black x-y axis then hit one of the following options.");
	printf("\n After sellecting options (1,3,4,5,6) left click the mouse to set your");
	printf("\n initial condition then right click the mouse to generate your next point.");
	printf("\n 1: Sets up the matrix that generated figure 1 in the paper.");
	printf("\n 3: Sets up the matrix that generated figure 3 in the paper.");
	printf("\n 4: Sets up the matrix that generated figure 4 in the paper.");
	printf("\n 5: Sets up the matrix that generated figure 5 in the paper.");
	printf("\n 6: Sets up the matrix that generated figure 6 in the paper.");
	printf("\n n: Allows the user to enter their own 2X2 matrix. Note you will enter these values in the linux terminal");
	printf("\n s: Takes a screan shot.");
	printf("\n c: Clears the screan.");
	printf("\n h: Displays the help screan again.");
	printf("\n q: Quits the program.");
}

void KeyPressed(unsigned char key, int x, int y)
{
	if(key == 'q')
	{
		glutDestroyWindow(g_win);
		exit(0);
	}
	
	if(key == 'c')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
	}
	
	if(key == 's')
	{	
		FILE* ScreenShotFile;
		int* buffer;
		const char* cmd = "ffmpeg -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
		              "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output1.mp4";
		ScreenShotFile = popen(cmd, "w");
		buffer = (int*)malloc(X_WINDOW*Y_WINDOW*sizeof(int));
		
		for(int i =0; i < 1; i++)
		{
			glReadPixels(5, 5, X_WINDOW, Y_WINDOW, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
			fwrite(buffer, sizeof(int)*X_WINDOW*Y_WINDOW, 1, ScreenShotFile);
		}
		
		pclose(ScreenShotFile);
		free(buffer);
		system("ffmpeg -i output1.mp4 screenShot.jpeg");
		system("rm output1.mp4");
	}
	
	if(key == 'h')
	{
		help();
	}
	
	if(key == '1') // Produces figure 1
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		A11 = 1.0;
		A12 = 1.0/2.0;
		A21 = 1.0/4.0;
		A22 = 3.0/4.0;
	}
	if(key == '3') // Produces figure 3
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		A11 = 1.0/2.0;
		A12 = 3.0/4.0;
		A21 = 1.0;
		A22 = 1.0/4.0;
	}
	if(key == '4') // Produces figure 
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		A11 = 1.1;
		A12 = 0.0;
		A21 = 0.0;
		A22 = 1.2;
	}
	if(key == '5') // Produces figure 5
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		A11 = 1.0;
		A12 = 0.0;
		A21 = 0.0;
		A22 = 1.2;
	}
	if(key == '6') // Produces figure 6
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		A11 = 1.0/2.0;
		A12 = 2.0;
		A21 = 1.0/2.0;
		A22 = -1.0/2.0;
	}
	if(key == 'n')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		printf("\n  Enter A11\n");
		scanf("%lf", &A11);
		printf("\n  Enter A12\n");
		scanf("%lf", &A12);
		printf("\n  Enter A21\n");
		scanf("%lf", &A21);
		printf("\n  Enter A22\n");
		scanf("%lf", &A22);
		printf("\n  Done. Go back to the and click on the x-y screan.\n");
	}
}

void display()
{
	glPointSize(2.0);
	glClear(GL_COLOR_BUFFER_BIT);
	place_axis();
	glutMouseFunc(mymouse);
}

int main(int argc, char** argv)
{
	glutInit(&argc,argv);
	glutInitWindowSize(X_WINDOW,Y_WINDOW);
	Buffer = new int[X_WINDOW*Y_WINDOW];
	glutInitWindowPosition(0,0);
	g_win = glutCreateWindow("Eigen Values and Eigen Vectors");
	glutKeyboardFunc(KeyPressed);
	glutDisplayFunc(display);
	help();
	glutMainLoop();
}
