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

        # Get the width and height of the camera feed
        # width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        # height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        # print(f"Camera resolution: {width}x{height}")
        
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
                print(hand_data)
        else:
            print("No hands detected.")

@app.route('/hand_landmarks', methods=['GET'])
def get_hand_landmarks():
    return jsonify(hand_data)

if __name__ == '__main__':
    capture_thread = threading.Thread(target=capture_hand_landmarks)
    capture_thread.start()
    app.run(host='0.0.0.0', port=1999, debug=True)
