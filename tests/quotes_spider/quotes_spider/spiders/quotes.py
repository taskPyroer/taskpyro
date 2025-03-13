import scrapy


class QuotesSpider(scrapy.Spider):
    # 爬虫的名称，必须唯一
    name = "quotes"
    # 起始 URL 列表，爬虫将从这些 URL 开始爬取
    start_urls = [
        'https://quotes.toscrape.com',
    ]

    def parse(self, response):
        # 遍历每个名言元素
        for quote in response.css('div.quote'):
            # 提取名言文本
            text = quote.css('span.text::text').get()
            # 提取作者姓名
            author = quote.css('small.author::text').get()
            # 提取标签列表
            tags = quote.css('div.tags a.tag::text').getall()

            # 生成包含提取信息的字典，并通过 yield 返回
            yield {
                'text': text,
                'author': author,
                'tags': tags
            }

        # 查找下一页的链接
        next_page = response.css('li.next a::attr(href)').get()
        if next_page is not None:
            # 如果存在下一页链接，使用 response.follow 方法继续爬取下一页，并调用 parse 方法处理响应
            yield response.follow(next_page, self.parse)