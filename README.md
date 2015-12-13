# Local Binary Feature based image alignment app #


**Summary** :
Initially, I had set out to build a Driving assistant app that could be run on iOS devices mounted as dashboard cameras facing the front of the car, to offer safety warnings such as when the driver is not maintaining a safe distance with the car in front, or if the car is veering outside the lane. Exploring the various image alignement techniques, I realized that most conventional image represenations are ill-suited to execution on mobile devices. So instead, I decided to pivot to working on this technical challenge of implementing a fast, mobile-friendly and efficient image tracking application.

I started working with Hatem Alismail, of the Robotics Institute at Carnegie Mellon University, to build a prototype application that made use of BitPlanes[1], a framework that Hatem was authoring (along with Brett Browning and Simon Lucey, also of the Robotics Institute) . Bitplanes was just the right fit for my driving assistant app-like ideas: a fast and robust image alignment framework well suited to the constraints of mobile devices.


**Background** : 
As described in “Bit-Planes: Dense Subpixel Alignment of Binary Descriptors.”[1], the bitplanes framework uses a descriptor called bit-planes, which is an adaptation of the simplest binary descriptor : LBP[2] descriptor (explained in Figure 1). The bit-planes descriptor is designed to work with the Lukas Kanade tracking algorithm to minimize the least squares distance between the template and the input image.

The framework is founded on the observation that binary features, despite being inherently discontinuous, are suitable for linearization followed by gradient-based optimization.[1]. Besides space and time efficiency, the other obvious benefit of the bitplanes descriptor is its robustness to geometric and photomoetric variance.

While using bit-planes as a descriptor allows me to optimize my app’s performance on an algorithmic level, the framework is also designed to make use of SIMD and NEON instructions, that further improve the performance of the app on the architectural level.

**Results**:
Initially I used the OpenCV cvPhotoCamera class to query for live frames, however, I later rewrote the entire app to use AVFoundation’s custom CaptureSession class as it yielded performance benefits and are also better support for the high frame rate features that I plan to add in the future.

My application successfully makes use of the Bitplanes framework for image alignment at frame rates as high as 120fps on the iPad Air 2. In Figure 3 you can see the basic user interface of the app that allows the user to select a template in the live view-frame using a resizeable bounding box. Once the template is set, the application begins to track the template in real time, overlaying the estimated homography onto the live view.

**Going Forward**
Using this application as the technical foundation for tracking, I plan to implement the driving assistant application that I had initially set out to build. Here’s a list of features that I plan to include :
- Support for iPhone 6(s) 240fps camera
- Lane Departure Warnings
- Maintain Safe Distance Warnings

For more details, please refer to the Final Project Report (to be uploaded soon).

**Citations**
- [1] H. Alismail, B. Browning, and S. Lucey, “Bit-Planes: Dense Subpixel Alignment of Binary Descriptors.” ArXiV 2016
- [2] T. Ojala, M. Pietikinen, and D. Harwood. A comparative study of texture measures with classification based on featured distributions. Pattern Recognition, 29:51?59, 1996. 1, 3
- [3] S. Gauglitz, T. Hllerer, and M. Turk. Evaluation of Interest Point Detectors and Feature Descriptors for Visual Tracking. International Journal of Computer Vision, 94(3):335?360, 2011. 5, 7
