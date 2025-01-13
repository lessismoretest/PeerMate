import Foundation

struct Prompt {
    static func generateHistoricalComparison(for person: String, at age: Int) -> String {
        """
        请以第一人称的口吻，描述如果\(person)活到今天，看到一个\(age)岁的人会说些什么。
        要求：
        1. 基于历史资料，说明\(person)在\(age)岁时的真实经历，
        2. 务必说说他在我这年龄时的今天在干啥（基于历史资料，如果没有，可以往前往后推一段时间，看看有什么相关事件，猜测推理出当时正在干什么，比如正在复盘xxx或正在准备xxx等
        3. 会对我这个\(age)岁的年轻人说些什么，精简些。
        4. 语气要像\(person)本人在说话，不要用文言文，引用除外。
        5. 回答要包含具体的历史事件和年份
        6. 字数在300字以内
        """
    }
    
    static func generateFamousPersonsList() -> String {
        """
        请生成一个包含30位世界历史上最著名的历史人物名字的列表。要求：
        1. 列表要多样化，包括政治家、科学家、艺术家、哲学家等不同领域的人物
        2. 包括不同国家和地区的代表性人物
        3. 包括不同历史时期的人物
        4. 使用中文名字
        5. 以JSON格式返回，格式如下：
        {"persons": ["人物1", "人物2", "人物3", ...]}
        
        只返回JSON数据，不要有其他解释或说明。
        """
    }
} 