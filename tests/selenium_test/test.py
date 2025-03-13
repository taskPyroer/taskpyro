from selenium import webdriver
from selenium.webdriver.chrome.service import Service
import os

service = Service()
options = webdriver.ChromeOptions()
options.add_argument('--no-sandbox')
options.add_argument('--headless')
options.add_argument('--disable-gpu')
options.add_argument('--disable-software-rasterizer')
options.add_argument('--disable-dev-shm-usage')

driver = webdriver.Chrome(service=service, options=options)

try:
    driver.get('https://www.bilibili.com')
    title = driver.title
    print(f"B 站网站的标题是: {title}")
except Exception as e:
    print(f"发生错误: {e}")
finally:
    driver.quit()