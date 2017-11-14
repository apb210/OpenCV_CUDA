// opencv1.cpp : Defines the entry point for the console application.
//
#include <stdio.h>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <stdio.h>
#include <iostream>
#include <cuda_runtime.h>
using namespace cv;

using namespace std;



__global__
void add(int n, int *x, int *y)
{

  int index = threadIdx.x;
  int stride = blockDim.x;
  for (int i = index; i < n; i += stride)
  {
	  y[i] = y[i]/3 +5;
	  x[i] = x[i] + 5;
  }

}


#pragma warning (disable : 4996)
int main(int argc, char* argv[])
{
	VideoCapture cap;
	//	// open the default camera, use something different from 0 otherwise;
	//	// Check VideoCapture documentation.
		if (!cap.open(0))
			return 0;

	for (;;)
	{
		Mat image;
		cap >> image;
		if (image.empty()) break; // end of video stream
		imshow("this is you, smile! :)", image);
		

	//Mat image;

	////The second parameter has been used to change the default return image
	//image = imread("C://Users//Apratim//source//repos//OpenCV//x64//Debug//data//lena.jpg", IMREAD_COLOR);

	//// if the argument is < 0 it returns the original image. 

	//if (image.empty())
	//{
	//	return -1;
	//}

	//namedWindow("Display window", WINDOW_AUTOSIZE); // Create a window for display.
	//												//! [window]
	//									//! [imshow]
	//imshow("Display window", image);                // Show our image inside it.
													//! [imshow]
		uint8_t* pixelPtr = (uint8_t*)image.data;
		int cn = image.channels();
		Scalar_<int> bgrPixel;

		//int *bPixelVal, *gPixelVal;
		int size = image.rows * image.cols;

		int *x, *y;

		// Allocate Unified Memory – accessible from CPU or GPU
		cudaMallocManaged(&x, size * sizeof(int));
		cudaMallocManaged(&y, size * sizeof(int));

		/*x = bPixelVal;
		y = gPixelVal;
	*/

		int c = 0;
		for (int i = 0; i < image.rows; i++)
		{
			for (int j = 0; j < image.cols; j++)
			{
				bgrPixel.val[0] = pixelPtr[i*image.cols*cn + j*cn + 0]; // B
				bgrPixel.val[1] = pixelPtr[i*image.cols*cn + j*cn + 1]; // G
				bgrPixel.val[2] = pixelPtr[i*image.cols*cn + j*cn + 2]; // R

				x[c] = pixelPtr[i*image.cols*cn + j*cn + 0]; // B
				y[c] = pixelPtr[i*image.cols*cn + j*cn + 1]; // G



				c = c++;

				// do something with BGR values...
			}
		}



		// Run kernel on 50K elements on the GPU
		add << <1, 1024 >> > (size, x, y);

		// Wait for GPU to finish before accessing on host
		cudaDeviceSynchronize();

		c = 0;
		for (int i = 0; i < image.rows; i++)
		{
			for (int j = 0; j < image.cols; j++)
			{
				image.at<Vec3b>(i, j)[0] = x[c];
				image.at<Vec3b>(i, j)[1] = y[c];
				//bPixelVal[c] = pixelPtr[i*image.cols*cn + j*cn + 2]; // R

				c = c++;

				// do something with BGR values...
			}
		}


		namedWindow("Output");
		imshow("Output", image);

		//cvWaitKey(0);

		
		// Free memory
		cudaFree(x);
		cudaFree(y);
		if (waitKey(10) == 27) break; // stop capturing by pressing ESC 
	}
	return 0;
}
