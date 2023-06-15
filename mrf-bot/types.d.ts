export type Config = {
  [email: string]: string; // { "email": "password" }
};

export type RewardsInfo = {
  dailySetPromotions: {
    [key: string]: PromotionInfo[];
  };
  punchCards: {
    name: string;
    parentPromotion: PromotionInfo;
    childPromotions: PromotionInfo[];
  }[];
  morePromotions: PromotionInfo[];
  userStatus: {
    counters: {
      pcSearch: PromotionInfo[];
      mobileSearch: PromotionInfo[];
      [key: string]: any;
    };
    [key: string]: any;
  };
  [key: string]: any;
};

type PromotionInfo = {
  name: string;
  complete: boolean;
  promotionType: 'quiz' | 'urlreward' | 'appstore' | 'search' | '';
  title: string;
  description: string;
  destinationUrl: string;
  [key: string]: any;
};

export type GoogleTrendsApiResult = {
  default: {
    trendingSearchesDays: {
      date: string;
      formattedDate: string;
      trendingSearches: {
        title: Title;
        relatedQueries: Title[];
        [key: string]: any;
      }[];
    }[];
    [key: string]: any;
  };
};

type Title = {
  query: string;
  exploreLink: string;
};
