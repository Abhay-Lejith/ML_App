from flask import Flask, request, jsonify
from tensorflow import keras
from keras.models import load_model
import numpy as np
import base64
from io import BytesIO
from PIL import Image,ImageOps

app = Flask(__name__)

class_labels = []

with open('labels.txt', 'r') as file:
    for line in file:
        parts = line.strip().split()
        if len(parts) > 1:
            class_labels.append(' '.join(parts[1:]))

# Load your pre-trained machine learning model here.
# Replace 'your_model.h5' with the actual filename of your model.
model = load_model('keras_model.h5')

@app.route('/predict', methods=['POST'])
def predict():
    try:
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

        # Process the predictions and return them.
        # Example:
        # class_labels = ['class1', 'class2', 'class3']
        # predicted_class = class_labels[np.argmax(predictions)]
        # confidence = np.max(predictions)
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

if __name__ == '__main__':
    app.run(debug=True)
