#include <linux/init.h>
#include <linux/module.h>
#include <linux/device.h>
#include <linux/platform_device.h>

#define GPIO_LED_PIN_NUM   55             /* gpio 1_23   */

/* 定义LED资源*/
static struct resource led_resources[] = {
     [0] = {
         .start  = GPIO_LED_PIN_NUM,
         .end    = GPIO_LED_PIN_NUM,
         .flags  = IORESOURCE_IO,
     },
 };

 static void led_platform_release(struct device *dev)
 {
     return;
 }

 /* 定义平台设备*/
 static struct platform_device led_platform_device = {
     .name         = "led",                /* platform_driver中，.name必须与该名字相同*/   
     .id          = -1,
     .num_resources  = ARRAY_SIZE(led_resources),
     .resource       = led_resources,
     .dev          = {
         /* Device 'led' does not have a release() function, it is broken and must be fixed. */
         .release        = led_platform_release,
         .platform_data  = NULL,
     },
 };

 static int __init led_platform_init(void)
 {
     int ret;

     ret = platform_device_register(&led_platform_device);
     if (ret < 0) {
         platform_device_put(&led_platform_device);
         return ret;
     }

    return 0;
 }

 static void __exit led_platform_exit(void)
 {
     platform_device_unregister(&led_platform_device);
 }

 module_init(led_platform_init);
 module_exit(led_platform_exit);

 MODULE_LICENSE("GPL");
 MODULE_AUTHOR("Chenxibing, linux@zlgmcu.com");
