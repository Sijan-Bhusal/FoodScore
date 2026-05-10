#!/usr/bin/env python3
"""
FoodScore - Bulk Product Importer
Adds multiple products to the database at once
"""

import requests
import json
import time
import os
import sys
from urllib.parse import urljoin

# API endpoint - configurable via environment variable
API_URL = os.getenv("FOODSCORE_API_URL", "http://localhost:8000")
PRODUCTS_ENDPOINT = urljoin(API_URL, "/products/")
REQUEST_TIMEOUT = 10  # seconds

# List of products to add
# Nutriments fields match what openfoodfacts.py fetches and score_service.py uses
products = [
    # Soft Drinks
    {
        "barcode": "5449000000996",
        "name": "Coca-Cola Original",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": ["e150d", "e338"],
        "nutriments": {"sugars_100g": 10.6, "saturated_fat_100g": 0, "salt_100g": 0.02, "fiber_100g": 0, "proteins_100g": 0}
    },
    {
        "barcode": "5449000134639",
        "name": "Sprite",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 9.0, "saturated_fat_100g": 0, "salt_100g": 0.02, "fiber_100g": 0, "proteins_100g": 0}
    },
    {
        "barcode": "5449000212177",
        "name": "Fanta Orange",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": ["e110", "e129"],
        "nutriments": {"sugars_100g": 11.0, "saturated_fat_100g": 0, "salt_100g": 0.02, "fiber_100g": 0, "proteins_100g": 0}
    },

    # Noodles
    {
        "barcode": "8901058171059",
        "name": "Wai Wai Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621", "e102"],
        "nutriments": {"sugars_100g": 2, "saturated_fat_100g": 3.5, "salt_100g": 1.8, "fiber_100g": 1, "proteins_100g": 8}
    },
    {
        "barcode": "8901058172001",
        "name": "Wai Wai Cup Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 3, "saturated_fat_100g": 3, "salt_100g": 1.5, "fiber_100g": 1, "proteins_100g": 7}
    },
    {
        "barcode": "8901058173008",
        "name": "Ruchi Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 2.5, "saturated_fat_100g": 3, "salt_100g": 1.6, "fiber_100g": 1, "proteins_100g": 7.5}
    },

    # Dairy
    {
        "barcode": "8901234567890",
        "name": "Fresh Dahi",
        "brand": "Sujal",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 4.5, "saturated_fat_100g": 1, "salt_100g": 0.12, "fiber_100g": 0, "proteins_100g": 3.5}
    },
    {
        "barcode": "8909876543210",
        "name": "Pasteurized Milk",
        "brand": "Nepal Dairy",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 4.8, "saturated_fat_100g": 1.2, "salt_100g": 0.1, "fiber_100g": 0, "proteins_100g": 3.2}
    },
    {
        "barcode": "8901234567880",
        "name": "Butter",
        "brand": "Amul",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 0.1, "saturated_fat_100g": 32, "salt_100g": 1.5, "fiber_100g": 0, "proteins_100g": 0.9}
    },

    # Biscuits & Snacks
    {
        "barcode": "8901725004400",
        "name": "Oreo Cookies",
        "brand": "Mondelez",
        "category": "Snacks",
        "additives": ["e322", "e476"],
        "nutriments": {"sugars_100g": 35, "saturated_fat_100g": 5, "salt_100g": 0.6, "fiber_100g": 2, "proteins_100g": 5}
    },
    {
        "barcode": "8901058100004",
        "name": "Parle G Biscuits",
        "brand": "Parle",
        "category": "Snacks",
        "additives": [],
        "nutriments": {"sugars_100g": 25, "saturated_fat_100g": 2.5, "salt_100g": 0.4, "fiber_100g": 2.5, "proteins_100g": 7}
    },
    {
        "barcode": "8901725004417",
        "name": "Good Day Biscuits",
        "brand": "Britannia",
        "category": "Snacks",
        "additives": ["e322"],
        "nutriments": {"sugars_100g": 28, "saturated_fat_100g": 3.5, "salt_100g": 0.5, "fiber_100g": 1.5, "proteins_100g": 6}
    },

    # Chips
    {
        "barcode": "5055060101212",
        "name": "Pringles Original",
        "brand": "Kellogg's",
        "category": "Chips",
        "additives": ["e621", "e631", "e627"],
        "nutriments": {"sugars_100g": 2, "saturated_fat_100g": 6, "salt_100g": 1.2, "fiber_100g": 2, "proteins_100g": 5}
    },
    {
        "barcode": "8901443010710",
        "name": "Lays Classic Salted",
        "brand": "PepsiCo",
        "category": "Chips",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 1, "saturated_fat_100g": 4, "salt_100g": 1.0, "fiber_100g": 2, "proteins_100g": 5}
    },

    # Juices
    {
        "barcode": "8901030510239",
        "name": "Real Fruit Juice Mango",
        "brand": "Dabur",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 12, "saturated_fat_100g": 0, "salt_100g": 0.01, "fiber_100g": 0.5, "proteins_100g": 0.5}
    },
    {
        "barcode": "8901030510246",
        "name": "Real Fruit Juice Mixed Fruit",
        "brand": "Dabur",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 11, "saturated_fat_100g": 0, "salt_100g": 0.01, "fiber_100g": 0.5, "proteins_100g": 0.5}
    },

    # Rice/Cooking
    {
        "barcode": "8901725000457",
        "name": "Basmati Rice",
        "brand": "India Gate",
        "category": "Cooking",
        "additives": [],
        "nutriments": {"sugars_100g": 0.1, "saturated_fat_100g": 0.03, "salt_100g": 0.01, "fiber_100g": 1, "proteins_100g": 7}
    },
    {
        "barcode": "8901050501013",
        "name": "Fortune Refined Oil",
        "brand": "Fortune",
        "category": "Cooking",
        "additives": [],
        "nutriments": {"sugars_100g": 0, "saturated_fat_100g": 2.5, "salt_100g": 0, "fiber_100g": 0, "proteins_100g": 0}
    }
]

def add_products():
    """Add all products to the database"""
    print("🚀 Starting bulk product import...")
    print(f"📍 API Endpoint: {PRODUCTS_ENDPOINT}")
    print("=" * 50)

    added = 0
    failed = 0
    skipped = 0

    for i, product in enumerate(products, 1):
        try:
            response = requests.post(
                PRODUCTS_ENDPOINT,
                json=product,
                timeout=REQUEST_TIMEOUT
            )

            if response.status_code == 200:
                added += 1
                try:
                    result = response.json()
                    print(f"✅ [{i}/{len(products)}] Added: {product['name']} (Score: {result.get('health_score', 'N/A')})")
                except json.JSONDecodeError:
                    print(f"✅ [{i}/{len(products)}] Added: {product['name']}")
            elif response.status_code == 409:
                skipped += 1
                print(f"⏭️  [{i}/{len(products)}] Skipped: {product['name']} (already exists)")
            else:
                failed += 1
                print(f"❌ [{i}/{len(products)}] Failed: {product['name']} - Status {response.status_code}")
                try:
                    error_detail = response.json()
                    print(f"   Error: {error_detail}")
                except json.JSONDecodeError:
                    print(f"   Response: {response.text[:200]}")

        except requests.exceptions.Timeout:
            failed += 1
            print(f"❌ [{i}/{len(products)}] Timeout: {product['name']} (request took too long)")
        except requests.exceptions.ConnectionError:
            failed += 1
            print(f"❌ Connection Error: Make sure the API is running at {PRODUCTS_ENDPOINT}")
            print("   You can set a custom API URL with: export FOODSCORE_API_URL=http://your-url")
            break
        except requests.exceptions.RequestException as e:
            failed += 1
            print(f"❌ [{i}/{len(products)}] Request Error for {product['name']}: {e}")
        except Exception as e:
            failed += 1
            print(f"❌ [{i}/{len(products)}] Error adding {product['name']}: {e}")

        # Small delay to avoid overwhelming the server
        time.sleep(0.1)

    print("\n" + "=" * 50)
    print("📊 Import Summary:")
    print(f"   ✅ Added: {added}")
    print(f"   ⏭️  Skipped (already exists): {skipped}")
    print(f"   ❌ Failed: {failed}")
    print(f"   📦 Total products in list: {len(products)}")

    if added > 0:
        print("\n🎉 Successfully added new products to FoodScore database!")

    # Return exit code based on success
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    exit_code = add_products()
    sys.exit(exit_code)
