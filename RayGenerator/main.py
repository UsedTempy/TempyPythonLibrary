from PIL import Image
import math

angle = math.radians(20)
res_out = 512
aa = 4
weight = 0.3

res = res_out * aa

img = Image.new("RGBA", (res, res))
img_pixels = img.load()

def transparency(dist):
    return 255 - (dist**weight * 255)

for x in range(0, res):
    for y in range(0 , res):
        dx = x - (res / 2)
        dy = y - (res / 2)

        theta = math.atan2(dy, dx)
        shade = math.floor(theta / angle - 0.5) % 2 == 0

        if shade:
            dist = math.sqrt(dx*dx + dy*dy) / (res / 2)
            alpha = min(max(math.floor(transparency(dist) + 0.5), 0), 255)

            img_pixels[x, y] = (255, 255, 255, alpha)



img = img.resize((res_out, res_out), resample=Image.LANCZOS)
img.save("out.png")