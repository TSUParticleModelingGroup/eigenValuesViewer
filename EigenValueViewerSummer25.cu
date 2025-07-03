//nvcc EigenValueViewerSummer25.cu -o temp -lglut -lm -lGLU -lGL
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

#define SCALE 20.0

#define X_WINDOW 1000
#define Y_WINDOW 1000

#define X_MAX SCALE
#define X_MIN -SCALE
#define X_SCALE 1.0

#define Y_MAX SCALE
#define Y_MIN -SCALE
#define Y_SCALE 1.0

FILE* ffmpeg;

//globals
double g_x;
double g_y;
static int g_win;
double A11, A12, A21, A22;
double Real1, Real2, Img1, Img2, EigenMag1, EigenMag2;
double VectorMag1, VectorMag2, Slope1, Slope2;
double Infinity = 100000000.0;
int AdjustA11, AdjustA12, AdjustA21, AdjustA22;
int SingleEigenValue;
int MovieOn = 0;
int* Buffer;
double2 EigenVector1, EigenVector2;
double Discriminate;
double XV1, YV1, XV2, YV2, Projection1, Projection2, Multiplier1, Multiplier2;
double TestX, TestY;

// Prototyping functions
double x_machine_to_x_screen(int);
double y_machine_to_y_screen(int);
double x_machine_to_x_world(int);
double y_machine_to_y_world(int);
double x_world_to_x_screen(double);
double y_world_to_y_screen(double);
void place_axis();
void placePoint(double, double);
void hitMatrix(double, double);
void mymouse(int, int, int, int);
void terminalPrint();
void KeyPressed(unsigned char, int, int);
void display();

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

void placeEigenVectors()
{
	if(Img1 == 0.0 && Img2 == 0.0)
	{ 
		// Placing eigen vectors
		glColor3f(0.0,1.0,0.0);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
			glVertex2f(x_world_to_x_screen(SCALE*EigenVector1.x/VectorMag1),y_world_to_y_screen(SCALE*EigenVector1.y/VectorMag1));
		glEnd();

		glColor3f(0.0,0.5,0.5);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
			glVertex2f(x_world_to_x_screen(SCALE*EigenVector2.x/VectorMag2),y_world_to_y_screen(SCALE*EigenVector2.y/VectorMag2));
		glEnd();
		
		glColor3f(1.0,0.0,0.0);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(-SCALE*EigenVector1.x/VectorMag1),y_world_to_y_screen(-SCALE*EigenVector1.y/VectorMag1));
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
		glEnd();
		
		glColor3f(0.5,0.0,0.5);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(-SCALE*EigenVector2.x/VectorMag2),y_world_to_y_screen(-SCALE*EigenVector2.y/VectorMag2));
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
		glEnd();
		
		// Placing dots magnitude of eigen value
		glColor3f(1.0,0.0,0.0);
		glPointSize(5);
		glBegin(GL_POINTS);
			glVertex2f(x_world_to_x_screen(EigenMag1*EigenVector1.x/VectorMag1),y_world_to_y_screen(EigenMag1*EigenVector1.y/VectorMag1));
			glVertex2f(x_world_to_x_screen(EigenMag2*EigenVector2.x/VectorMag2),y_world_to_y_screen(EigenMag2*EigenVector2.y/VectorMag2));
		glEnd();
		
		// Placing one unit on eigen vector
		glColor3f(1.0,1.0,1.0);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
			glVertex2f(x_world_to_x_screen(EigenVector1.x/VectorMag1),y_world_to_y_screen(EigenVector1.y/VectorMag1));
		glEnd();

		glBegin(GL_LINE_LOOP);
			glVertex2f(x_world_to_x_screen(0.0),y_world_to_y_screen(0.0));
			glVertex2f(x_world_to_x_screen(EigenVector2.x/VectorMag2),y_world_to_y_screen(EigenVector2.y/VectorMag2));
		glEnd();
	}

	glFlush();
}

void placePoint(double x, double y)
{
	glColor3f(1.0,0.0,1.0);
	glBegin(GL_POINTS);
		glVertex2f(x_world_to_x_screen(TestX),y_world_to_y_screen(TestY));
	glEnd();
	glFlush();
	
	glColor3f(0.0,1.0,1.0);
	glBegin(GL_POINTS);
		glVertex2f(x_world_to_x_screen(XV1),y_world_to_y_screen(YV1));
	glEnd();
	glFlush();
	
	glColor3f(0.0,0.5,1.0);
	glBegin(GL_POINTS);
		glVertex2f(x_world_to_x_screen(XV2),y_world_to_y_screen(YV2));
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

void findValues()
{
	Discriminate = (A11 - A22)*(A11 - A22) + 4.0*(A12*A21);
	
	if(0.0 < Discriminate)
	{
		Real1 = 0.5*(A11 + A22 - sqrt(Discriminate));
		Real2 = 0.5*(A11 + A22 + sqrt(Discriminate));
		Img1 = 0.0;
		Img2 = 0.0;
		SingleEigenValue = 0;
	}
	else if(0.0 == Discriminate)
	{
		Real1 = 0.5*(A11 + A22);
		Real2 = 0.5*(A11 + A22);
		Img1 = 0.0;
		Img2 = 0.0;
		SingleEigenValue = 1;
	}
	else
	{
		Real1 = 0.5*(A11 + A22);
		Real2 = 0.5*(A11 + A22);
		Img1 = -0.5*sqrt(-Discriminate);
		Img2 = +0.5*sqrt(-Discriminate);
		SingleEigenValue = 0;
	}
	EigenMag1 = sqrt(Img1*Img1 + Real1*Real1);
	EigenMag2 = sqrt(Img2*Img2 + Real2*Real2);
	
	if(A12 != 0.0)
	{
		EigenVector1.x = 1.0;
		EigenVector1.y = (A22 - A11 - sqrt(Discriminate))/(2.0*A12);
		
		EigenVector2.x = 1.0;
		EigenVector2.y = (A22 - A11 + sqrt(Discriminate))/(2.0*A12);
	}
	else
	{
		if((A11 - A22) != 0.0)
		{
			EigenVector1.x = 1.0;
			EigenVector1.y = A21/(A11 - A22);
			
			EigenVector2.x = 0.0;
			EigenVector2.y = 1.0;
		}
		else
		{
			EigenVector1.x = 0.0;
			EigenVector1.y = 1.0;
			
			EigenVector2.x = 0.0;
			EigenVector2.y = 1.0;
		}
		
	}
	VectorMag1 = sqrt(EigenVector1.x*EigenVector1.x + EigenVector1.y*EigenVector1.y);
	VectorMag2 = sqrt(EigenVector2.x*EigenVector2.x + EigenVector2.y*EigenVector2.y);
	
	if(EigenVector1.x != 0.0)
	{
		Slope1 = EigenVector1.y/EigenVector1.x;
	}
	else
	{
		Slope1 = Infinity + 1.0;
	}
	
	if(EigenVector2.x != 0.0)
	{
		Slope2 = EigenVector2.y/EigenVector2.x;
	}
	else
	{
		Slope2 = Infinity + 1.0;
	}
}

void terminalPrint()
{
	system("clear");
	
	if(AdjustA11)
	{
		printf("\n  \033[1;32mA11\033[0m  A12   %f  %f", A11, A12);
		printf("\n  A21  A22   %f  %f", A21, A22);
	}
	else if(AdjustA12)
	{
		printf("\n  A11  \033[1;32mA12\033[0m   %f  %f", A11, A12);
		printf("\n  A21  A22   %f  %f", A21, A22);
	}
	else if(AdjustA21)
	{
		printf("\n  A11  A12   %f  %f", A11, A12);
		printf("\n  \033[1;32mA21\033[0m  A22   %f  %f", A21, A22);
	}
	else if(AdjustA22)
	{
		printf("\n  A11  A12   %f  %f", A11, A12);
		printf("\n  A21  \033[1;32mA22\033[0m   %f  %f", A21, A22);
	}
	else
	{
		printf("\n  A11  A12   %f  %f", A11, A12);
		printf("\n  A21  A22   %f  %f", A21, A22);
	}
	printf("\n");
	
	
	printf("\n  EigenValue1 =   %f + %fi: mag = %f", Real1, Img1, EigenMag1);
	printf("\n  EigenValue2 =   %f + %fi: mag = %f", Real2, Img2, EigenMag2);
	printf("\n  (A11 - A22)^2 + 4.0*(A12*A21) Discriminate =   %f", Discriminate);
	printf("\n");
	
	printf("\n  EigenVector1 =   <%f, %f>", EigenVector1.x, EigenVector1.y);
	printf("\n  EigenVector2 =   <%f, %f>", EigenVector2.x, EigenVector2.y);
	printf("\n");
	
	printf("\n  Slope1 = %f", Slope1);
	printf("\n  Slope2 = %f", Slope2);
	printf("\n");
	
	printf("\n  x = %f\n",g_x);
	printf("  y = %f\n",g_y);
	
	printf("\n  x test = %f\n",TestX);
	printf("  y test = %f\n",TestY);
	
	printf("\n");
}

void mymouse(int button, int state, int x, int y)
{	
	if(state == GLUT_DOWN)
	{
		if(button == GLUT_LEFT_BUTTON)
		{
			g_x = x_machine_to_x_world(x);
			g_y = y_machine_to_y_world(y);
			
			glColor3f(1.0,1.0,0.0);
			glPointSize(5);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(g_x),y_world_to_y_screen(g_y));
			glEnd();
			glFlush();
			
			TestX = g_x;
			TestY = g_y;
			
			if(Infinity <= Slope1)
			{
				XV1 = 0.0;
				if(Infinity <= Slope2)
				{
					YV1 = TestY;
				}
				else
				{
					YV1 = -Slope2*TestX + TestY;
				}
				Projection1 = YV1;
				
			}
			else if(Slope1 != 0.0)
			{
				if(Infinity <= Slope2)
				{
					XV1 = TestX;
					YV1 = Slope1*XV1;
					Projection1 = sqrt(XV1*XV1 + YV1*YV1);
					if(XV1*EigenVector1.x < 0.0) Projection1 = -Projection1;
				}
				else
				{
					XV1 = ((-Slope2)*TestX + TestY)/(Slope1 - Slope2);
					YV1 = Slope1*XV1;
					Projection1 = sqrt(XV1*XV1 + YV1*YV1);
					if(XV1*EigenVector1.x < 0.0) Projection1 = -Projection1;
				}
			}
			else
			{
				XV1 = TestX;
				YV1 = 0.0;
				Projection1 = XV1;
			}
			
			if(Infinity <= Slope2)
			{
				XV2 = 0.0;
				if(Infinity <= Slope1)
				{
					YV2 = TestY;
				}
				else
				{
					YV2 = -Slope1*TestX + TestY;
				}
				Projection2 = YV2;
			}
			else if(Slope2 != 0.0)
			{
				XV2 = ((-Slope1)*TestX + TestY)/(Slope2 - Slope1);
				YV2 = Slope2*XV2;
				Projection2 = sqrt(XV2*XV2 + YV2*YV2);
				if(XV2*EigenVector2.x < 0.0) Projection2 = -Projection2;
			}
			else
			{
				XV2 = TestX;
				YV2 = 0.0;
				Projection2 = XV2;
			}
			
			Multiplier1 = Real1;
			Multiplier2 = Real2;
			
			// This should go right on top of the original point.
			glColor3f(1.0,0.0,1.0);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(TestX),y_world_to_y_screen(TestY));
			glEnd();
			glFlush();
			
			// This should be the projection of the point on to the first vector.
			glColor3f(0.0,1.0,1.0);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(XV1),y_world_to_y_screen(YV1));
			glEnd();
			glFlush();
			
			// This should be the projection of the point on to the second vector.
			glColor3f(0.0,0.5,1.0);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(XV2),y_world_to_y_screen(YV2));
			glEnd();
			glFlush();
	
			//placePoint(g_x,g_y);
			terminalPrint();
		}
		else
		{
			hitMatrix(g_x,g_y);
			
			glColor3f(0.0,1.0,0.0);
			glPointSize(5);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(g_x),y_world_to_y_screen(g_y));
			glEnd();
			glFlush();
			
			if(Infinity <= Slope1)
			{
				XV1 = 0.0;
				YV1 = Multiplier1*Projection1;
			}
			else if(Slope1 != 0.0)
			{
				XV1 = Multiplier1*Projection1*EigenVector1.x/VectorMag1;
				YV1 = Multiplier1*Projection1*EigenVector1.y/VectorMag1;
			}
			else
			{
				XV1 = Multiplier1*Projection1;
				YV1 = 0.0;
			}
			
			if(Infinity <= Slope2)
			{
				XV2 = 0.0;
				YV2 = Multiplier2*Projection2;
			}
			if(Slope2 != 0.0)
			{
				XV2 = Multiplier2*Projection2*EigenVector2.x/VectorMag2;
				YV2 = Multiplier2*Projection2*EigenVector2.y/VectorMag2;
			}
			else
			{
				XV2 = Multiplier2*Projection2;
				YV2 = 0.0;
			}
			
			// This should be the projection of the point on to the first vector.
			glColor3f(0.0,1.0,1.0);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(XV1),y_world_to_y_screen(YV1));
			glEnd();
			glFlush();
			
			// This should be the projection of the point on to the second vector.
			glColor3f(0.0,0.5,1.0);
			glBegin(GL_POINTS);
				glVertex2f(x_world_to_x_screen(XV2),y_world_to_y_screen(YV2));
			glEnd();
			glFlush();
			
			TestX = XV1 + XV2;
			TestY = YV1 + YV2;
			
			Multiplier1 *= Real1;
			Multiplier2 *= Real2;
	
			//placePoint(g_x,g_y);
			terminalPrint();
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
	if(key == 'k')
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		placeEigenVectors();
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
		//placePoint(g_x,g_y);
		terminalPrint();
	}
	
	if(key == 'a')
	{
		AdjustA11 = 1;
		AdjustA12 = 0;
		AdjustA21 = 0;
		AdjustA22 = 0;
		terminalPrint();
	}
	if(key == 'b')
	{
		AdjustA11 = 0;
		AdjustA12 = 1;
		AdjustA21 = 0;
		AdjustA22 = 0;
		terminalPrint();
	}
	if(key == 'c')
	{
		AdjustA11 = 0;
		AdjustA12 = 0;
		AdjustA21 = 1;
		AdjustA22 = 0;
		terminalPrint();
	}
	if(key == 'd')
	{
		AdjustA11 = 0;
		AdjustA12 = 0;
		AdjustA21 = 0;
		AdjustA22 = 1;
		terminalPrint();
	}
	
	double adjustment = 0.01;
	if(key == '+')
	{
		if(AdjustA11 == 1)      A11 += adjustment;
		else if(AdjustA12 == 1) A12 += adjustment; 
		else if(AdjustA21 == 1) A21 += adjustment; 
		else if(AdjustA22 == 1) A22 += adjustment; 
		findValues();
		terminalPrint();
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		placeEigenVectors();
	}
	if(key == '-')
	{
		if(AdjustA11 == 1)      A11 -= adjustment;
		else if(AdjustA12 == 1) A12 -= adjustment; 
		else if(AdjustA21 == 1) A21 -= adjustment; 
		else if(AdjustA22 == 1) A22 -= adjustment;
		findValues();
		terminalPrint();
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		placeEigenVectors(); 
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
		printf("\n k: Clear");
		printf("\n a: Adjust A11");
		printf("\n b: Adjust A12");
		printf("\n c: Adjust A21");
		printf("\n d: Adjust A22");
		printf("\n +/-: Adjust up/down");
		printf("\n M/m: Movie on/off");
		printf("\n s: Screen Shot");
		printf("\n");
		printf("\n t: Read starting x and y from screen.");
		printf("\n 0: Eigenvalue 5/4 eigenvector <2,1> Eigenvalue 1/2 eigenvector <1,-1>");
		printf("\n 1: Eigenvalue 3/2 eigenvector <1,1> Eigenvalue -1/2 eigenvector <1,-1>");
		printf("\n 2: Eigenvalue sqrt(5)/2 eigenvector <sqrt(5)+1,1> Eigenvalue -sqrt(3)/2 eigenvector <-sqrt(3)+1,1> equal size eigen values one negative makes it alternate");
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
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
		findValues();
		terminalPrint();
		placeEigenVectors();
	}
	if(key == '!') // 
	{
		glClear(GL_COLOR_BUFFER_BIT);
		place_axis();
		
		A11 = (0.0);
		A12 = (2.0);
		A21 = (3.0);
		A22 = (0.0);
		findValues();
		terminalPrint();
		placeEigenVectors();
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
	findValues();
	terminalPrint();
	placeEigenVectors();
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
