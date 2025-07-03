//nvcc EigenValueViewerBells.cu -o bells -lglut -lm -lGLU -lGL
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
int MovieOn = 0;
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
	
	if(MovieOn == 1)
	{
		glReadPixels(5, 5, X_WINDOW, Y_WINDOW, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
		fwrite(Buffer, sizeof(int)*X_WINDOW*Y_WINDOW, 1, ffmpeg);
	}
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

void KeyPressed(unsigned char key, int x, int y)
{
	float tempx;
	float tempy;
	float damp;
	if(key == 'q')
	{
		glutDestroyWindow(g_win);
		exit(0);
	}
	if(key == 't')
	{
		printf("\n  Inter start x value\n");
		scanf("%f", &tempx);
		g_x = tempx;
		printf("\n  Inter start y value\n");
		scanf("%f", &tempy);
		g_y = tempy;
		
		glColor3f(1.0,0.0,0.0);
		placePoint(g_x,g_y);
		printPoint();
	}
	if(key == 'c')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
	}
	
	if(key == 'm')
	{
		// Setting up the movie buffer.
		const char* cmd = "ffmpeg -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
		              "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output.mp4";
		ffmpeg = popen(cmd, "w");
		//Buffer = new int[XWindowSize*YWindowSize];
		Buffer = (int*)malloc(X_WINDOW*Y_WINDOW*sizeof(int));
		MovieOn = 1;
	}
	if(key == 'M')
	{
		pclose(ffmpeg);
		MovieOn = 0;
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
		printf("\n q: Quit");
		printf("\n c: Clear");
		printf("\n M/m: Movie on/off");
		printf("\n s: Screen Shot");
		printf("\n");
		printf("\n t: Read starting x and y from screen.");
		printf("\n 0: Eigenvalue 5/4 eigenvector <2,1> Eigenvalue 1/2 eigenvector <1,-1>");
		printf("\n 1: Eigenvalue 3/2 eigenvector <1,1> Eigenvalue -1/2 eigenvector <1,-1>");
		printf("\n 2: Eigenvalue sqrt(3)/2 eigenvector <sqrt(3)+1,1> Eigenvalue -sqrt(3)/2 eigenvector <-sqrt(3)+1,1> equal size eigen values one negative makes it alternate");
		printf("\n 3: Eigenvalue 1.1 eigenvector <1,0> Eigenvalue 1.2 eigenvector <0,1>");
		printf("\n 4: Eigenvalue 1 eigenvector <1,0> Eigenvalue 1.2 <0,1>");
		printf("\n 5: Eigenvalue 1.1 eigenvector <1,1> Eigenvalue 1.2 eigenvector <0,1>");
		printf("\n 6: Eigenvalue -0.5 eigenvector <-3,4> Eigenvalue 1.25 eigenvector <1,1>");
		printf("\n 7: Eigenvalue i eigenvector <-2-i,5> Eigenvalue -i eigenvector <-2+i,5>  spiral 4 cycle");
		printf("\n 8: Eigenvalue 1/2 + i*sqrt(2)/2 eigenvector <i*sqrt(2),1> Eigenvalue 1/2 - i*sqrt(2)/2 eigenvector <-i*sqrt(2),1>  spiral in");
		printf("\n 9: Eigenvalue damp*(1+i*sqrt(2)) eigenvector <i*sqrt(2),1> Eigenvalue damp*(1-i*sqrt(2)) eigenvector <-i*sqrt(2),1>  spiral out");
		printf("\n");
	}
	
	if(key == '0') // Eigenvalue 5/4 eigenvector <2,1> Eigenvalue 1/2 eigenvector <1,-1> .2 is the break point
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (0.25);
		A11 = (4.0*damp);
		A12 = (2.0*damp);
		A21 = (1.0*damp);
		A22 = (3.0*damp);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '1') // Eigenvalue 3/2 eigenvector <1,1> Eigenvalue -1/2 eigenvector <1,-1>
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(1.0/2.0);
		A12 = damp*(1.0);
		A21 = damp*(1.0);
		A22 = damp*(1.0/2.0);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '2') // Eigenvalue sqrt(3)/2 eigenvector <sqrt(3)+1,1> Eigenvalue -sqrt(3)/2 eigenvector <-sqrt(3)+1,1> equal size eigen values one negative makes it alternate
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(1.0/2.0);
		A12 = damp*(2.0);
		A21 = damp*(1.0/2.0);
		A22 = damp*(-1.0/2.0);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '3')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(1.1);
		A12 = damp*(0.0);
		A21 = damp*(0.0);
		A22 = damp*(1.2);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '4')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(1.0);
		A12 = damp*(0.0);
		A21 = damp*(0.0);
		A22 = damp*(1.2);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '5')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		float a = 1.1;
		float b = 1.2;
		A11 = damp*(a);
		A12 = damp*(0.0);
		A21 = damp*(b-a);
		A22 = damp*(b);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '6')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(0.5);
		A12 = damp*(0.75);
		A21 = damp*(1.0);
		A22 = damp*(0.25);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '7') // Eigenvalue i eigenvector <-2-i,5> Eigenvalue -i eigenvector <-2+i,5>  spiral 4 cycle
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(2.0);
		A12 = damp*(1.0);
		A21 = damp*(-5.0);
		A22 = damp*(-2.0);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '8') // Eigenvalue 1/2 + i*sqrt(2)/2 eigenvector <i*sqrt(2),1> Eigenvalue 1/2 - i*sqrt(2)/2 eigenvector <-i*sqrt(2),1>  spiral in
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (1.0);
		A11 = damp*(1.0/2.0);
		A12 = damp*(-1.0);
		A21 = damp*(1.0/2.0);
		A22 = damp*(1.0/2.0);
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '9') // Eigenvalue damp*(1+i*sqrt(2)) eigenvector <i*sqrt(2),1> Eigenvalue damp*(1-i*sqrt(2)) eigenvector <-i*sqrt(2),1>  spiral out
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		damp = (3.0/5.0);
		A11 = (1.0)*damp;
		A12 = (-2.0)*damp;
		A21 = (1.0)*damp;
		A22 = (1.0)*damp;
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
	if(key == '!') // 
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		printf("\n  Inter start a value\n");
		scanf("%f", &damp);
		
		A11 = (0.0);
		A12 = (-1.0);
		A21 = (1.0);
		A22 = damp;
		
		printf("\n********** Matric *********");
		printf("\n %f  %f", A11, A12);
		printf("\n %f  %f", A21, A22);
		printf("\n***************************\n");
	}
}

void display()
{
	glPointSize(2.0);
	glClear(GL_COLOR_BUFFER_BIT);
	place_axis();
	float damp = (0.25);
	A11 = (4.0*damp);
	A12 = (2.0*damp);
	A21 = (1.0*damp);
	A22 = (3.0*damp);
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
	glutMainLoop();
}
