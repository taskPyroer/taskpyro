
from DrissionPage import ChromiumOptions, ChromiumPage

try:
    co = ChromiumOptions().auto_port()
    co.set_argument('--no-sandbox')
    co.set_argument('--headless=new')
    co.set_argument('--single-process')  # 单进程模式
    co.set_argument('--disable-gpu')  # 禁用GPU加速
    page = ChromiumPage(co)
    page.get('about:blank')
    page.get('http://www.bilibili.com/')
    title = page.title
    print(title)
    page.close()
    page.quit()
finally:
    if 'page' in locals():
        page.quit()