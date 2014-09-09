//
//  GameConfig.h
//  DragonSoul
//
//  Created by LEON on 12-10-12.
//
//

#ifndef __DragonSoul__GameConfig__
#define __DragonSoul__GameConfig__

class GameConfig {
public:
    // 返回数据存档，每次进入后台保存数据时都会调用此方法
    static char * getGameData(char *buf, int buf_size);
    // 初始化游戏存档，每次进入游戏时都会调用此方法设置最新的存档数据
    static void setGameData(const char *data);
    // 从Facebook导入进度
    static void setGameDataFromFB(const char *data);
    // 添加游戏资源, type:1-星星，2－宝石，3－经验, 4-等级，101-生命，102-加5步
    static void addGameResource(int type, int val);
    // 获取游戏资源, type:1-星星，2－宝石，3－经验，4－等级, 101-生命，102-加5步
    static int getGameResource(int type);
    // IAP道具购买成功,发放金币和道具
    static void purchaseSucceed(const char *iapID);
    // 设置IAP道具的奖励数量
    static void setGoldsAmount();
    // 获取IAP道具对应的金币数量,必须用短ID，这样能支持安卓版和发行多版本，比如正常ID是com.topgame.farmmania.gold1, 你只需要用 gold1 即可。
    static int  getIapItemCoinNumber(const char *iapID);

    // 显示系统通知
    static void onGetSystemNotice(const char *noticeMesg);
    static void setIsLoadingDone();
    
    // 导出关键的数值，进行保护
    static int  dumpProtectedData(char *buf, int len);
    // 获得关卡等候时间, 单位是秒
    static int  getQuestWaitingTime();
};

#endif /* defined(__DragonSoul__GameConfig__) */
