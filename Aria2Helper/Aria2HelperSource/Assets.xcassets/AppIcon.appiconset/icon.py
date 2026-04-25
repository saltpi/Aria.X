import os
import json
from PIL import Image

def generate_icons(source_image_path, json_path):
    # 1. 检查文件是否存在
    if not os.path.exists(source_image_path):
        print(f"❌ 错误: 找不到源图片 {source_image_path}")
        return
    if not os.path.exists(json_path):
        print(f"❌ 错误: 找不到 {json_path}")
        return

    # 2. 打开 1024x1024 源图
    try:
        img = Image.open(source_image_path)
        print(f"✅ 成功加载源图: {source_image_path} (当前尺寸: {img.size})")
    except Exception as e:
        print(f"❌ 无法打开图片: {e}")
        return

    # 3. 读取 Contents.json
    with open(json_path, 'r', encoding='utf-8') as f:
        contents = json.load(f)

    base_dir = os.path.dirname(json_path)
    if not base_dir:
        base_dir = "."

    # 4. 遍历 images 列表并生成对应尺寸的图片
    for item in contents.get('images', []):
        size_str = item.get('size')
        if not size_str:
            continue

        # 解析尺寸和缩放比例 (例如: size="32x32", scale="2x")
        w, h = map(float, size_str.split('x'))
        scale_str = item.get('scale', '1x')
        scale = float(scale_str.replace('x', ''))

        # 计算目标实际像素大小
        target_w = int(w * scale)
        target_h = int(h * scale)

        # 获取或生成文件名
        filename = item.get('filename')
        if not filename:
            idiom = item.get('idiom', 'universal')
            # 默认生成 png 格式以支持透明度
            filename = f"Icon-{idiom}-{size_str}@{scale_str}.png"
            item['filename'] = filename  # 将新生成的文件名回写到 JSON 字典中

        output_path = os.path.join(base_dir, filename)

        # 调整图片大小 (使用 LANCZOS 算法保证缩放质量)
        resized_img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)

        # 处理格式兼容性：如果原图带有 Alpha 通道 (RGBA)，但需要保存为 JPG，则转换模式
        if filename.lower().endswith(('.jpg', '.jpeg')):
            if resized_img.mode in ('RGBA', 'P'):
                resized_img = resized_img.convert('RGB')

        # 保存图片
        resized_img.save(output_path)
        print(f"➡️ 已生成: {filename} (实际像素: {target_w}x{target_h})")

    # 5. 将更新了文件名的信息覆盖写回 Contents.json
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(contents, f, indent=2)
    print("\n✅ 所有图标生成完毕，Contents.json 已自动更新！")

if __name__ == "__main__":
    # 配置你的文件路径
    # 假设源图叫 "1024.png"，与脚本同级目录
    SOURCE_ICON_PATH = "appicon.jpg" 
    JSON_FILE_PATH = "Contents.json"

    generate_icons(SOURCE_ICON_PATH, JSON_FILE_PATH)