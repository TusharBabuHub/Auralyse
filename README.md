# Auralyse  
A Flutter based front-end application which has been built to interact with API to iodentify emotions in recorded audio.  
The API repository can be found at https://github.com/TusharBabuHub/Auralyse_API  
The application has been built as an android application.   
While there are folders for other operating systems available, they have not been tested and should work with minimal changes.  
To connect to API, the url and the secret key needs to be stored in path ~/lib/auth/secrets.dart  
Please provide the URL as const String url = <'https://your-url-link-here/predict'>;  
Please provide the key as const String apiSecretKey = 'your-secret-key-here';  

The API returns a set of images in a zip file, which are the circumplex chart of the audio, analysed for each second.  
The application unzips and displays these visulaisations along with play of the audio.  

The User Interface has been kept simple with only one option initially to record audio.  
Post analysis, the audio is allowed to be replayed and the visualisation is shown.
