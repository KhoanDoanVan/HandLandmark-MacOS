from flask import Flask, jsonify
import cv2
import mediapipe as mp
import threading

app = Flask(__name__)

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)

hand_data = {"landmarks": []}

def capture_hand_landmarks():
    global hand_data
    cap = cv2.VideoCapture(1)

    if not cap.isOpened():
        print("Error: Could not open camera!")
        return

    while True:
        success, image = cap.read()
        if not success:
            print("Failed to capture image from camera.")
            continue

        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = hands.process(image_rgb)

        if results.multi_hand_landmarks:
            print("Hand landmarks detected!")
            for hand_landmarks in results.multi_hand_landmarks:
                hand_data["landmarks"] = [
                    {"x": lm.x, "y": lm.y, "z": lm.z} for lm in hand_landmarks.landmark
                ]
        else:
            print("No hands detected.")

@app.route('/hand_landmarks', methods=['GET'])
def get_hand_landmarks():
    return jsonify(hand_data)

if __name__ == '__main__':
    capture_thread = threading.Thread(target=capture_hand_landmarks)
    capture_thread.start()
    app.run(host='0.0.0.0', port=1999, debug=True)

# import cv2
# import mediapipe as mp

# # Load a sample image with a hand visible in it
# image = cv2.imread("hand_image.jpg")

# # Convert the image to RGB
# image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# # Initialize mediapipe hand detector
# mp_hands = mp.solutions.hands
# hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# # Process the image
# results = hands.process(image_rgb)

# # Check if hands were detected
# if results.multi_hand_landmarks:
#     print("Hands detected!")
# else:
#     print("No hands detected in static image.")
