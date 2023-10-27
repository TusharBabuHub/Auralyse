# Auralyse  
A Flutter based front-end application which has been built to interact with API to iodentify emotions in recorded audio.  
The API repository can be found at https://github.com/TusharBabuHub/Auralyse_API  
The application has been built as an android application.   
While there are folders for other operating systems available, they have not been tested and should work with minimal changes.  
To connect to API, the url and the secret key needs to be stored in path ~/lib/auth/secrets.dart  
Please provide the URL as const String url = 'https://<your-url-link-here>/predict';  
Please provide the key as const String apiSecretKey = 'your-secret-key-here';  

The API returns a set of images in a zip file, which are the circumplex chart of the audio, analysed for each second.  
The application unzips and displays these visulaisations along with play of the audio.  

The User Interface has been kept simple with only one option initially to record audio.  
Post analysis, the audio is allowed to be replayed and the visualisation is shown.  

### How to use the Application:

The design of the application has been kept simple.  
It constitutes of just 2 buttons one to record and other to play.  
To start with, touch on the Mic icon in the middle of the application.  
This would commence the recording of audio by the application.  
The icon would now show an image of Hearing.  
To stop recording, just touch on the same icon.  
An Image and a play button along with an image is shown on the screen.  
Pressing the play icon would replay the audio recorded and would display the emotion for the interval of one second.  
To start again just press the Mic icon again.
