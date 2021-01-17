// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract InterestCalculator {
    using SafeMath for uint;
    uint private constant maxDays = 301;

    function initInterestForDayArray() private pure returns (uint[] memory) {
        uint[] memory interestForDays = new uint[](maxDays);

        interestForDays[0] = 0;
        interestForDays[1] = 1;
        interestForDays[2] = 2;
        interestForDays[3] = 3;
        interestForDays[4] = 4;
        interestForDays[5] = 5;
        interestForDays[6] = 6;
        interestForDays[7] = 6;
        interestForDays[8] = 7;
        interestForDays[9] = 8;
        interestForDays[10] = 9;
        interestForDays[11] = 10;
        interestForDays[12] = 11;
        interestForDays[13] = 12;
        interestForDays[14] = 13;
        interestForDays[15] = 14;
        interestForDays[16] = 15;
        interestForDays[17] = 16;
        interestForDays[18] = 18;
        interestForDays[19] = 19;
        interestForDays[20] = 20;
        interestForDays[21] = 21;
        interestForDays[22] = 22;
        interestForDays[23] = 23;
        interestForDays[24] = 24;
        interestForDays[25] = 25;
        interestForDays[26] = 26;
        interestForDays[27] = 27;
        interestForDays[28] = 29;
        interestForDays[29] = 30;
        interestForDays[30] = 31;
        interestForDays[31] = 32;
        interestForDays[32] = 33;
        interestForDays[33] = 34;
        interestForDays[34] = 36;
        interestForDays[35] = 37;
        interestForDays[36] = 38;
        interestForDays[37] = 39;
        interestForDays[38] = 41;
        interestForDays[39] = 42;
        interestForDays[40] = 43;
        interestForDays[41] = 44;
        interestForDays[42] = 46;
        interestForDays[43] = 47;
        interestForDays[44] = 48;
        interestForDays[45] = 50;
        interestForDays[46] = 51;
        interestForDays[47] = 52;
        interestForDays[48] = 54;
        interestForDays[49] = 55;
        interestForDays[50] = 57;
        interestForDays[51] = 58;
        interestForDays[52] = 59;
        interestForDays[53] = 61;
        interestForDays[54] = 62;
        interestForDays[55] = 64;
        interestForDays[56] = 65;
        interestForDays[57] = 67;
        interestForDays[58] = 68;
        interestForDays[59] = 70;
        interestForDays[60] = 71;
        interestForDays[61] = 73;
        interestForDays[62] = 74;
        interestForDays[63] = 76;
        interestForDays[64] = 77;
        interestForDays[65] = 79;
        interestForDays[66] = 81;
        interestForDays[67] = 82;
        interestForDays[68] = 84;
        interestForDays[69] = 86;
        interestForDays[70] = 87;
        interestForDays[71] = 89;
        interestForDays[72] = 91;
        interestForDays[73] = 92;
        interestForDays[74] = 94;
        interestForDays[75] = 96;
        interestForDays[76] = 98;
        interestForDays[77] = 99;
        interestForDays[78] = 101;
        interestForDays[79] = 103;
        interestForDays[80] = 105;
        interestForDays[81] = 107;
        interestForDays[82] = 108;
        interestForDays[83] = 110;
        interestForDays[84] = 112;
        interestForDays[85] = 114;
        interestForDays[86] = 116;
        interestForDays[87] = 118;
        interestForDays[88] = 120;
        interestForDays[89] = 122;
        interestForDays[90] = 124;
        interestForDays[90] = 126;
        interestForDays[92] = 128;
        interestForDays[93] = 130;
        interestForDays[94] = 132;
        interestForDays[95] = 134;
        interestForDays[96] = 136;
        interestForDays[97] = 138;
        interestForDays[98] = 141;
        interestForDays[99] = 143;
        interestForDays[100] = 145;
        interestForDays[101] = 147;
        interestForDays[102] = 149;
        interestForDays[103] = 152;
        interestForDays[104] = 154;
        interestForDays[105] = 156;
        interestForDays[106] = 159;
        interestForDays[107] = 161;
        interestForDays[108] = 163;
        interestForDays[109] = 166;
        interestForDays[110] = 168;
        interestForDays[111] = 170;
        interestForDays[112] = 173;
        interestForDays[113] = 175;
        interestForDays[114] = 178;
        interestForDays[115] = 180;
        interestForDays[116] = 183;
        interestForDays[117] = 185;
        interestForDays[118] = 188;
        interestForDays[119] = 190;
        interestForDays[120] = 193;
        interestForDays[121] = 196;
        interestForDays[122] = 198;
        interestForDays[123] = 201;
        interestForDays[124] = 204;
        interestForDays[125] = 206;
        interestForDays[126] = 209;
        interestForDays[127] = 212;
        interestForDays[128] = 215;
        interestForDays[129] = 218;
        interestForDays[130] = 221;
        interestForDays[131] = 223;
        interestForDays[132] = 226;
        interestForDays[133] = 229;
        interestForDays[134] = 232;
        interestForDays[135] = 235;
        interestForDays[136] = 238;
        interestForDays[137] = 241;
        interestForDays[138] = 244;
        interestForDays[139] = 247;
        interestForDays[140] = 251;
        interestForDays[141] = 254;
        interestForDays[142] = 257;
        interestForDays[143] = 260;
        interestForDays[144] = 263;
        interestForDays[145] = 267;
        interestForDays[146] = 270;
        interestForDays[147] = 273;
        interestForDays[148] = 277;
        interestForDays[149] = 280;
        interestForDays[150] = 283;
        interestForDays[151] = 287;
        interestForDays[152] = 290;
        interestForDays[153] = 294;
        interestForDays[154] = 297;
        interestForDays[155] = 301;
        interestForDays[156] = 305;
        interestForDays[157] = 308;
        interestForDays[158] = 312;
        interestForDays[159] = 316;
        interestForDays[160] = 319;
        interestForDays[161] = 323;
        interestForDays[162] = 327;
        interestForDays[163] = 331;
        interestForDays[164] = 335;
        interestForDays[165] = 339;
        interestForDays[166] = 343;
        interestForDays[167] = 347;
        interestForDays[168] = 351;
        interestForDays[169] = 355;
        interestForDays[170] = 359;
        interestForDays[171] = 363;
        interestForDays[172] = 367;
        interestForDays[173] = 371;
        interestForDays[174] = 375;
        interestForDays[175] = 380;
        interestForDays[176] = 384;
        interestForDays[177] = 388;
        interestForDays[178] = 393;
        interestForDays[179] = 397;
        interestForDays[180] = 402;
        interestForDays[181] = 406;
        interestForDays[182] = 411;
        interestForDays[183] = 415;
        interestForDays[184] = 420;
        interestForDays[185] = 425;
        interestForDays[186] = 429;
        interestForDays[187] = 434;
        interestForDays[188] = 439;
        interestForDays[189] = 444;
        interestForDays[190] = 449;
        interestForDays[191] = 454;
        interestForDays[192] = 459;
        interestForDays[193] = 464;
        interestForDays[194] = 469;
        interestForDays[195] = 474;
        interestForDays[196] = 479;
        interestForDays[197] = 484;
        interestForDays[198] = 489;
        interestForDays[199] = 495;
        interestForDays[200] = 500;
        interestForDays[201] = 506;
        interestForDays[202] = 511;
        interestForDays[203] = 516;
        interestForDays[204] = 522;
        interestForDays[205] = 528;
        interestForDays[206] = 533;
        interestForDays[207] = 539;
        interestForDays[208] = 545;
        interestForDays[209] = 551;
        interestForDays[210] = 556;
        interestForDays[211] = 562;
        interestForDays[212] = 568;
        interestForDays[213] = 574;
        interestForDays[214] = 580;
        interestForDays[215] = 586;
        interestForDays[216] = 593;
        interestForDays[217] = 599;
        interestForDays[218] = 605;
        interestForDays[219] = 611;
        interestForDays[220] = 618;
        interestForDays[221] = 624;
        interestForDays[222] = 631;
        interestForDays[223] = 637;
        interestForDays[224] = 644;
        interestForDays[225] = 651;
        interestForDays[226] = 658;
        interestForDays[227] = 664;
        interestForDays[228] = 671;
        interestForDays[229] = 678;
        interestForDays[230] = 685;
        interestForDays[231] = 692;
        interestForDays[232] = 699;
        interestForDays[233] = 707;
        interestForDays[234] = 714;
        interestForDays[235] = 721;
        interestForDays[236] = 729;
        interestForDays[237] = 736;
        interestForDays[238] = 744;
        interestForDays[239] = 751;
        interestForDays[240] = 759;
        interestForDays[241] = 767;
        interestForDays[242] = 774;
        interestForDays[243] = 782;
        interestForDays[244] = 790;
        interestForDays[245] = 798;
        interestForDays[246] = 806;
        interestForDays[247] = 814;
        interestForDays[248] = 823;
        interestForDays[249] = 831;
        interestForDays[250] = 839;
        interestForDays[251] = 848;
        interestForDays[252] = 856;
        interestForDays[253] = 865;
        interestForDays[254] = 874;
        interestForDays[255] = 882;
        interestForDays[256] = 891;
        interestForDays[257] = 900;
        interestForDays[258] = 909;
        interestForDays[259] = 918;
        interestForDays[260] = 927;
        interestForDays[261] = 937;
        interestForDays[262] = 946;
        interestForDays[263] = 955;
        interestForDays[264] = 965;
        interestForDays[265] = 974;
        interestForDays[266] = 984;
        interestForDays[267] = 994;
        interestForDays[268] = 1004;
        interestForDays[269] = 1014;
        interestForDays[270] = 1024;
        interestForDays[271] = 1034;
        interestForDays[272] = 1044;
        interestForDays[273] = 1054;
        interestForDays[274] = 1065;
        interestForDays[275] = 1075;
        interestForDays[276] = 1086;
        interestForDays[277] = 1096;
        interestForDays[278] = 1107;
        interestForDays[279] = 1118;
        interestForDays[280] = 1129;
        interestForDays[281] = 1140;
        interestForDays[282] = 1151;
        interestForDays[283] = 1162;
        interestForDays[284] = 1174;
        interestForDays[285] = 1185;
        interestForDays[286] = 1197;
        interestForDays[287] = 1208;
        interestForDays[288] = 1220;
        interestForDays[289] = 1232;
        interestForDays[290] = 1244;
        interestForDays[291] = 1256;
        interestForDays[292] = 1268;
        interestForDays[293] = 1281;
        interestForDays[294] = 1293;
        interestForDays[295] = 1306;
        interestForDays[296] = 1318;
        interestForDays[297] = 1331;
        interestForDays[298] = 1344;
        interestForDays[299] = 1357;
        interestForDays[300] = 1370;

        return interestForDays;
    }

    function initCumulativeInterestForDays(uint[] memory interestForDays) private pure returns (uint[] memory) {
        uint[] memory cumulativeInterestForDays = new uint[](maxDays);

        uint sum;
        for(uint i = 0; i < maxDays; i++) {
            sum = sum.add(interestForDays[i]);
            cumulativeInterestForDays[i] = sum;
        }

        return cumulativeInterestForDays;
    }

    function getInterestForDay(uint _day) internal pure returns(uint) {
        require(_day < maxDays);
        uint[] memory interestForDays = initInterestForDayArray();
        return interestForDays[_day];
    }

    function getInterestTillDays(uint _day) internal pure returns(uint) {
        require(_day < maxDays);
        uint[] memory interestForDays = initInterestForDayArray();
        uint[] memory cumulativeInterestForDays = initCumulativeInterestForDays(interestForDays);
        return cumulativeInterestForDays[_day];
    }

    function getEstimateDaysFromInterest(uint interest) internal pure returns(uint) {
        uint[] memory interestForDays = initInterestForDayArray();
        uint[] memory cumulativeInterestForDays = initCumulativeInterestForDays(interestForDays);

        // If interest is less then user could have gotten in 1 day, return 0;
        if (interest < cumulativeInterestForDays[1]) {
            return 0;
        }

        for(uint i = 1; i < maxDays - 1; i++) {
            if (cumulativeInterestForDays[i] < interest && cumulativeInterestForDays[i + 1] > interest) {
                return i;
            }
        }

        // If interest is more then any amount we have, return maxDays - 1 // 300
        return maxDays - 1;
    }
}
