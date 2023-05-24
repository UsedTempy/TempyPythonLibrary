import os
from flask import Flask, jsonify, request
from PIL import Image
from io import BytesIO
from moviepy.editor import VideoFileClip
import base64
from multiprocessing import Pool, cpu_count

# Creates a new local API
app = Flask(__name__)

# Set the desired frame rate (fps)
fps = 30

MovieList = {
    "ShrekMovie": "VideoFolder/ShrekMOV.mov"
}

def get_frame_data(frame):
    img = Image.fromarray(frame)
    img = img.resize((160, 90))
    img = img.convert("RGB")
    return img.tobytes().hex()

@app.route('/video', methods=['GET'])
def get_video():
    print("Received")

    # Get the Movie Name, Buffer Length, and Start Point from the URL parameters
    movie_name = request.args.get('movie_name')
    buffer_length = int(request.args.get('buffer_length', default=800))
    start_point = int(request.args.get('start_point', default=0))

    print(start_point, buffer_length)

    # Check if the movie name exists in the MovieList dictionary
    if movie_name not in MovieList:
        return jsonify({'error': 'Invalid movie name'})

    # Get the file path of the movie
    movie_path = MovieList[movie_name]

    # Open Video Clip
    clip = VideoFileClip(movie_path)

    # Set the start point and end point for the buffer
    end_point = start_point + buffer_length

    # Create a list to store the bitmap data for each table
    tables = []
    bitmap_data_list = []

    with Pool() as pool:
        for i, frame_data in enumerate(pool.imap_unordered(get_frame_data, clip.iter_frames(fps=fps), chunksize=1), start=1):
            # Skip frames until the start point is reached
            if i < start_point:
                continue

            # Append the encoded bitmap data to the list
            bitmap_data_list.append(frame_data)

            # If the desired buffer length is reached, add the current table to the list of tables
            if len(bitmap_data_list) == buffer_length:
                tables.append(bitmap_data_list)
                bitmap_data_list = []

            # Break the loop if the end point is reached
            if i == end_point:
                break

    # If there are any remaining frames, add them to a new table
    if bitmap_data_list:
        tables.append(bitmap_data_list)

    # Convert each table to a list of Base64-encoded strings
    tables = [[base64.b64encode(bytes.fromhex(frame_data)).decode('utf-8') for frame_data in table] for table in tables]

    # Send the tables in a JSON response
    jsonifiedTable = jsonify(tables)
    print("Return Data")
    return jsonifiedTable

@app.route('/movies', methods=['GET'])
def get_movies():
    return {}

if __name__ == '__main__':
    app.run(debug=True)