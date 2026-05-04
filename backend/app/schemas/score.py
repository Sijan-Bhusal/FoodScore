from pydantic import BaseModel

class TrafficLight(BaseModel):
    color: str
    label: str

class ScoreOut(BaseModel):
    product_id: str
    health_score: int
    is_harmful: bool
    traffic_light: TrafficLight
    flagged_ingredients: list[dict]