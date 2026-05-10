#!/usr/bin/env python3
"""
FoodScore - Bulk Product Importer
Adds multiple products to the database at once
"""

import requests
import json
import time

# API endpoint
API_URL = "http://localhost:8000/products/"

# List of products to add
products = [
    # Soft Drinks
    {
        "barcode": "5449000000996",
        "name": "Coca-Cola Original",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": ["e150d", "e338"],
        "nutriments": {"sugars_100g": 10.6, "saturated_fat_100g": 0, "salt_100g": 0, "fiber_100g": 0, "proteins_100g": 0}
    },
    {
        "barcode": "5449000134639",
        "name": "Sprite",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 9.0, "saturated_fat_100g": 0, "salt_100g": 0, "fiber_100g": 0, "proteins_100g": 0}
    },
    {
        "barcode": "5449000212177",
        "name": "Fanta Orange",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "additives": ["e110", "e129"],
        "nutriments": {"sugars_100g": 11.0, "saturated_fat_100g": 0, "salt_100g": 0, "fiber_100g": 0, "proteins_100g": 0}
    },

    
    # Noodles
    {
        "barcode": "8901058171059",
        "name": "Wai Wai Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621", "e102"],
        "nutriments": {"sugars_100g": 2, "saturated_fat_100g": 8, "salt_100g": 2.1, "fiber_100g": 1, "proteins_100g": 8}
    },
    {
        "barcode": "8901058172001",
        "name": "Wai Wai Cup Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 3, "saturated_fat_100g": 7, "salt_100g": 2.0, "fiber_100g": 1, "proteins_100g": 7}
    },
    {
        "barcode": "8901058173008",
        "name": "Ruchi Noodles",
        "brand": "CG Foods",
        "category": "Noodles",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 2.5, "saturated_fat_100g": 7.5, "salt_100g": 2.2, "fiber_100g": 1, "proteins_100g": 7.5}
    },
    
    # Dairy
    {
        "barcode": "8901234567890",
        "name": "Fresh Dahi",
        "brand": "Sujal",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 4.5, "saturated_fat_100g": 1.5, "salt_100g": 0.1, "fiber_100g": 0, "proteins_100g": 3.5}
    },
    {
        "barcode": "8909876543210",
        "name": "Pasteurized Milk",
        "brand": "Nepal Dairy",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 4.8, "saturated_fat_100g": 1.8, "salt_100g": 0.1, "fiber_100g": 0, "proteins_100g": 3.2}
    },
    {
        "barcode": "8901234567880",
        "name": "Butter",
        "brand": "Amul",
        "category": "Dairy",
        "additives": [],
        "nutriments": {"sugars_100g": 0.1, "saturated_fat_100g": 51, "salt_100g": 1.5, "fiber_100g": 0, "proteins_100g": 0.9}
    },
    
    # Biscuits & Snacks
    {
        "barcode": "8901725004400",
        "name": "Oreo Cookies",
        "brand": "Mondelez",
        "category": "Snacks",
        "additives": ["e322", "e476"],
        "nutriments": {"sugars_100g": 35, "saturated_fat_100g": 12, "salt_100g": 0.8, "fiber_100g": 2, "proteins_100g": 5}
    },
    {
        "barcode": "8901058100004",
        "name": "Parle G Biscuits",
        "brand": "Parle",
        "category": "Snacks",
        "additives": [],
        "nutriments": {"sugars_100g": 25, "saturated_fat_100g": 6, "salt_100g": 0.5, "fiber_100g": 2.5, "proteins_100g": 7}
    },
    {
        "barcode": "8901725004417",
        "name": "Good Day Biscuits",
        "brand": "Britannia",
        "category": "Snacks",
        "additives": ["e322"],
        "nutriments": {"sugars_100g": 28, "saturated_fat_100g": 8, "salt_100g": 0.6, "fiber_100g": 1.5, "proteins_100g": 6}
    },
    
    # Chips
    {
        "barcode": "5055060101212",
        "name": "Pringles Original",
        "brand": "Kellogg's",
        "category": "Chips",
        "additives": ["e621", "e631", "e627"],
        "nutriments": {"sugars_100g": 2, "saturated_fat_100g": 15, "salt_100g": 1.5, "fiber_100g": 2, "proteins_100g": 5}
    },
    {
        "barcode": "8901443010710",
        "name": "Lays Classic Salted",
        "brand": "PepsiCo",
        "category": "Chips",
        "additives": ["e621"],
        "nutriments": {"sugars_100g": 1, "saturated_fat_100g": 10, "salt_100g": 1.2, "fiber_100g": 2, "proteins_100g": 5}
    },
    
    # Juices
    {
        "barcode": "8901030510239",
        "name": "Real Fruit Juice Mango",
        "brand": "Dabur",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 12, "saturated_fat_100g": 0, "salt_100g": 0, "fiber_100g": 0.5, "proteins_100g": 0.5}
    },
    {
        "barcode": "8901030510246",
        "name": "Real Fruit Juice Mixed Fruit",
        "brand": "Dabur",
        "category": "Beverages",
        "additives": [],
        "nutriments": {"sugars_100g": 11, "saturated_fat_100g": 0, "salt_100g": 0, "fiber_100g": 0.5, "proteins_100g": 0.5}
    },
    
    # Rice/Cooking
    {
        "barcode": "8901725000457",
        "name": "Basmati Rice",
        "brand": "India Gate",
        "category": "Cooking",
        "additives": [],
        "nutriments": {"sugars_100g": 0.1, "saturated_fat_100g": 0.1, "salt_100g": 0, "fiber_100g": 1, "proteins_100g": 7}
    },
    {
        "barcode": "8901050501013",
        "name": "Fortune Refined Oil",
        "brand": "Fortune",
        "category": "Cooking",
        "additives": [],
        "nutriments": {"sugars_100g": 0, "saturated_fat_100g": 14, "salt_100g": 0, "fiber_100g": 0, "proteins_100g": 0}
    }
]

def add_products():
    """Add all products to the database"""
    print("🚀 Starting bulk product import...")
    print("=" * 50)
    
    added = 0
    failed = 0
    skipped = 0
    
    for i, product in enumerate(products, 1):
        try:
            response = requests.post(API_URL, json=product)
            
            if response.status_code == 200:
                added += 1
                result = response.json()
                print(f"✅ [{i}/{len(products)}] Added: {product['name']} (Score: {result.get('health_score', 'N/A')})")
            elif response.status_code == 409:
                skipped += 1
                print(f"⏭️  [{i}/{len(products)}] Skipped: {product['name']} (already exists)")
            else:
                failed += 1
                print(f"❌ [{i}/{len(products)}] Failed: {product['name']} - {response.text}")
        
        except requests.exceptions.ConnectionError:
            failed += 1
            print(f"❌ [{i}/{len(products)}] Connection Error: Make sure the API is running at {API_URL}")
            break
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

if __name__ == "__main__":
    add_products()