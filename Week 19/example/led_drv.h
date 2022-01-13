 /*程序清单2.20LED驱动文件*/
 #ifndef _LED_DRV_H                       
 #define _LED_DRV_H                       
                                          
 #define LED_IOC_MAGIC  'L'               
 #define LED_ON      _IO(LED_IOC_MAGIC, 0)