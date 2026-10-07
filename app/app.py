import os
from flask import Flask
import pymysql

app = Flask(__name__)

# --- Database connection settings (read from environment variables) ---
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_USER = os.environ.get("DB_USER", "admin")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "project1db")


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


def setup_table():
    """Creates the products table and inserts sample rows if empty."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    price DECIMAL(10,2) NOT NULL
                )
            """)
            cursor.execute("SELECT COUNT(*) AS count FROM products")
            if cursor.fetchone()["count"] == 0:
                cursor.executemany(
                    "INSERT INTO products (name, price) VALUES (%s, %s)",
                    [
                        ("Oak Dining Table", 349.99),
                        ("Velvet Accent Chair", 189.50),
                        ("Bookshelf - 5 Tier", 129.00),
                        ("Ceramic Table Lamp", 42.75),
                        ("Linen Sofa", 799.00),
                    ]
                )
        conn.commit()
    finally:
        conn.close()


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/")
def index():
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT name, price FROM products")
            products = cursor.fetchall()
    finally:
        conn.close()

    rows_html = "".join(
        f"<tr><td>{p['name']}</td><td>${p['price']:.2f}</td></tr>"
        for p in products
    )

    return f"""
    <html>
    <head>
        <title>Product Catalog</title>
        <style>
            body {{ font-family: Arial, sans-serif; background: #f5f5f5; padding: 40px; }}
            h1 {{ color: #1a3c6e; }}
            table {{ border-collapse: collapse; width: 60%; background: white; box-shadow: 0 1px 4px rgba(0,0,0,0.1); }}
            th, td {{ padding: 12px 16px; text-align: left; border-bottom: 1px solid #eee; }}
            th {{ background: #1a3c6e; color: white; }}
            .badge {{ display: inline-block; background: #e8f0e0; color: #2d5016; padding: 4px 10px; border-radius: 4px; font-size: 13px; margin-bottom: 20px; }}
        </style>
    </head>
    <body>
        <div class="badge">Served via Flask &rarr; nginx &rarr; RDS (private subnet)</div>
        <h1>Product Catalog</h1>
        <table>
            <tr><th>Product</th><th>Price</th></tr>
            {rows_html}
        </table>
    </body>
    </html>
    """


if __name__ == "__main__":
    setup_table()
    app.run(host="0.0.0.0", port=5000)
