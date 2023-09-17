from flask import Flask, request, jsonify
from tensorflow import keras
from keras.models import load_model
import numpy as np
import base64
from io import BytesIO
from PIL import Image,ImageOps
from skimage import io,transform
from skimage.transform import resize
from skimage.exposure import equalize_adapthist
from PIL import ImageOps

app = Flask(__name__)



def predict_fundus():
    try:
        class_labels = []

        with open('fundus_v2_labels.txt', 'r') as file:
            for line in file:
                parts = line.strip().split()
                if len(parts) > 1:
                    class_labels.append(' '.join(parts[1:]))

        model = load_model('fundus_model_v2.h5')
        # Receive image data as base64 and decode it.
        data = request.json.get('image_bytes')
        image_bytes = base64.b64decode(data)

        # Convert to PIL Image.
        image = Image.open(BytesIO(image_bytes))

        data = np.ndarray(shape=(1, 224, 224, 3), dtype=np.float32)
        # Preprocess the image as needed for your model.
        # Example:
        if image.mode != 'RGB':
            image = image.convert('RGB')

        image = ImageOps.fit(image, (224,224), Image.Resampling.LANCZOS)
        image_ = np.asarray(image)
        # image = image / 255.0  # Normalize the pixel values
        n_image = (image_.astype(np.float32) / 127.5) - 1
        # image = np.expand_dims(image, axis=0)  # Add batch dimension

        data[0] = n_image

        # Make predictions with your model.
        predictions = model.predict(data)

        predicted_class_index = np.argmax(predictions)

        predicted_class_name = class_labels[predicted_class_index]

        confidence = float(predictions[0][predicted_class_index])

        response = {
            'predicted_class': predicted_class_name,
            'confidence': confidence,
        }


        return jsonify(response)

    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500
    
def predict_xray():
    try:
        class_labels = []

        with open('xray_labels.txt', 'r') as file:
            for line in file:
                parts = line.strip().split()
                if len(parts) > 1:
                    class_labels.append(' '.join(parts[1:]))

        model = load_model('xray_model_v2.h5')
        # Receive image data as base64 and decode it.
        data = request.json.get('image_bytes')
        image_bytes = base64.b64decode(data)

        # Convert to PIL Image.
        image = Image.open(BytesIO(image_bytes))
    
        # Ensure image is in grayscale mode
        if image.mode != 'L':
            image = image.convert('L')
        
        # Resize the image to (128, 128)
        image = ImageOps.fit(image, (128,128))
        
        # Apply CLAHE to enhance contrast (consistent with training)
        image = equalize_adapthist(np.asarray(image))
        
        # Convert the image to a numpy array and expand dimensions
        image = np.expand_dims(image, axis=-1)
        
        # Prepare the data array
        data = np.ndarray(shape=(1, 128, 128, 1), dtype=np.float32)
        data[0] = image
        
        # Make predictions with your model.
        predictions = model.predict(data)

        # Sort the predictions in descending order
        sorted_predictions = np.argsort(predictions[0])[::-1]

        # Get the top two predicted class indices and their corresponding confidence levels
        top1_class_index = sorted_predictions[0]
        top2_class_index = sorted_predictions[1]

        top1_class = class_labels[top1_class_index]
        top2_class = class_labels[top2_class_index]

        confidence_1 = float(predictions[0][top1_class_index])
        confidence_2 = float(predictions[0][top2_class_index])


        response = {
            'predicted_class_1': top1_class,
            'predicted_class_2':top2_class,
            'confidence_1': confidence_1,
            'confidence_2': confidence_2,
        }


        return jsonify(response)

    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/predict/<string:img>', methods=['POST'])
def predict(img):
    if(img == 'fundus'):
        response = predict_fundus()
    elif(img == 'xray'):
        response = predict_xray()
    return response

if __name__ == '__main__':
    app.run(debug=True)
