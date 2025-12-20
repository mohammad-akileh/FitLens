# functions/main.py

import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn, options
import vertexai
from vertexai.generative_models import GenerativeModel, Part
import json
import keys

firebase_admin.initialize_app()
vertexai.init(project=keys.fitlens_project, location="us-central1")

# --- 🔒 THE SECRET PASSWORD ---
# Change this to anything you want, but keep it the same in Flutter!
SECRET_KEY = keys.SECRET_KEY

# --- CHEF #1: The Scanner ---
@https_fn.on_request(
    region="us-central1",
    memory=options.MemoryOption.MB_512,
    timeout_sec=60,
)
def generate_meal_data(req: https_fn.Request) -> https_fn.Response:
    try:
        # 1. Handle CORS
        if req.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-App-Secret', # Added X-App-Secret
                'Access-Control-Max-Age': '3600'
            }
            return https_fn.Response('', status=204, headers=headers)

        headers = {'Access-Control-Allow-Origin': '*'}

        # 🛑 SECURITY CHECK (The Bouncer)
        # We check if the app sent the secret header
        app_secret = req.headers.get('X-App-Secret')
        if app_secret != SECRET_KEY:
            print("⛔ BLOCKED: Unauthorized App Version")
            return https_fn.Response("Update your app to use this feature.", status=403, headers=headers)

        # 2. Get File
        uploaded_file = req.files.get('file')
        if not uploaded_file:
            return https_fn.Response("No file uploaded", status=400, headers=headers)

        print(f"🚀 RECEIVED IMAGE: {uploaded_file.filename}")

        # 3. Force correct MIME type
        mime_type = uploaded_file.content_type
        if not mime_type or "image" not in mime_type:
            mime_type = "image/jpeg"

        image_bytes = uploaded_file.read()
        image_part = Part.from_data(data=image_bytes, mime_type=mime_type)

        # 4. Call Gemini
        model = GenerativeModel("gemini-2.5-flash")

        prompt = """
        You are an expert nutritionist. Identify ALL distinct food items in this image.
        Return ONLY a JSON LIST. 
        IMPORTANT: ESTIMATE values. Do NOT return 0.
        Format:
        [
            {
                "food_name": "Name",
                "serving_unit": "1 Unit",
                "calories_per_serving": 100,
                "protein_per_serving": 10,
                "carbs_per_serving": 10,
                "fat_per_serving": 5
            }
        ]
        """

        response = model.generate_content([image_part, prompt])
        clean_text = response.text.replace('```json', '').replace('```', '').strip()

        return https_fn.Response(clean_text, status=200, headers=headers)

    except Exception as e:
        print(f"❌ ERROR: {e}")
        return https_fn.Response(str(e), status=500, headers={'Access-Control-Allow-Origin': '*'})


# --- CHEF #2: The Corrector ---
@https_fn.on_request(
    region="us-central1",
    memory=options.MemoryOption.MB_512,
    timeout_sec=30,
)
def correct_meal_item(req: https_fn.Request) -> https_fn.Response:
    try:
        # 1. Handle CORS
        if req.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-App-Secret',
                'Access-Control-Max-Age': '3600'
            }
            return https_fn.Response('', status=204, headers=headers)

        headers = {'Access-Control-Allow-Origin': '*'}

        # 🛑 SECURITY CHECK (The Bouncer)
        app_secret = req.headers.get('X-App-Secret')
        if app_secret != SECRET_KEY:
            print("⛔ BLOCKED: Unauthorized App Version")
            return https_fn.Response("Update your app to use this feature.", status=403, headers=headers)

        wrong_item = req.form.get("wrong_item")
        correction = req.form.get("correction")
        uploaded_file = req.files.get('file')

        if not correction:
            return https_fn.Response("Missing correction text", status=400, headers=headers)

        print(f"✏️ CORRECTING: {wrong_item} -> {correction}")

        model = GenerativeModel("gemini-2.5-flash")

        prompt = f"""
        You are an expert nutritionist.
        The user identified: "{wrong_item}" but said it is actually "{correction}".
        Please provide the nutritional info for 1 STANDARD SERVING of "{correction}".
        IMPORTANT: ESTIMATE values. Do NOT return 0.
        Return ONLY a raw JSON object.
        """

        parts = [prompt]
        if uploaded_file:
            mime_type = uploaded_file.content_type
            if not mime_type or "image" not in mime_type:
                mime_type = "image/jpeg"
            image_bytes = uploaded_file.read()
            parts.append(Part.from_data(data=image_bytes, mime_type=mime_type))

        response = model.generate_content(parts)
        clean_text = response.text.replace('```json', '').replace('```', '').strip()

        return https_fn.Response(clean_text, status=200, headers=headers)

    except Exception as e:
        print(f"❌ ERROR: {e}")
        return https_fn.Response(str(e), status=500, headers=headers)