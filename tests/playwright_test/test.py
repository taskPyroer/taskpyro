import asyncio
from playwright.async_api import async_playwright
import subprocess

# 安装 Chromium
subprocess.run(["playwright", "install", "chromium"], check=True)

async def main():
    async with async_playwright() as p:
        # 启动 Chromium 浏览器
        browser = await p.chromium.launch(headless=True)
        # 创建一个新的浏览器上下文
        context = await browser.new_context()
        # 在上下文中创建一个新的页面
        page = await context.new_page()

        try:
            # 打开百度首页
            await page.goto('http://www.bilibili.com/')

            # 获取搜索结果页面的标题
            title = await page.title()
            print(f"搜索结果页面的标题是: {title}")

        except Exception as e:
            print(f"发生错误: {e}")
        finally:
            # 关闭浏览器
            await browser.close()


if __name__ == "__main__":
    asyncio.run(main())