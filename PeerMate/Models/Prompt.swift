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
} 