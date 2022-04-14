/* On my honor, I have neither given nor received unauthorized aid on this assignment. */
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <bitset>

using namespace std;

// Read instructions and data from a file
vector<string> read(const string& filepath) {
    ifstream file(filepath);
    vector<string> lines;
    if (file.is_open()) {
        while (file) {
            string line;
            file >> line;
            if (!line.empty())
                lines.push_back(line);
        }
    }
    file.close();
    return lines;
}

// Takes the and of two 32-bit strings
string andop(const string& a, const string& b) {
    string ans;
    for (int i = 0; i < a.size(); i++) {
        ans += to_string((a[i] == '1') && (b[i] == '1') ? 1 : 0);
    }
    return ans;
}

// Takes the or of two 32-bit strings
string orop(const string& a, const string& b) {
    string ans;
    for (int i = 0; i < a.size(); i++) {
        ans += to_string((a[i] == '1') || (b[i] == '1') ? 1 : 0);
    }
    return ans;
}

// Takes the xor of two 32-bit strings
string xorop(const string& a, const string& b) {
    string ans;
    for (int i = 0; i < a.size(); i++) {
        ans += to_string(((a[i] == '1') && (b[i] == '0')) || ((a[i] == '0') && (b[i] == '1')) ? 1 : 0);
    }
    return ans;
}

// Convert a binary string to integer
int convert(const string& in, bool isSigned) {
    string input = in;
    if (isSigned && input[0] == '1') {
        // Flip every bit
        for (auto & c : input) {
            if (c == '0') {
                c = '1';
            } else {
                c = '0';
            }
        }
        // Add 1 and return
        return (stoi(input, nullptr, 2) + 1) * -1;
    } else {
        return stoi(input, nullptr, 2);
    }
}

// Convert a signed integer to 32-bit 2's complement string
string to2s(const int& in) {
    return bitset<32>(in).to_string();
}

// Display register data
void printReg(const vector<int>& reg, ofstream& out) {
    out << "Registers";
    out << endl << "X00:";
    for (int i = 0; i < 8; i++)
        out << "\t" << reg[i];
    out << endl << "X08:";
    for (int i = 8; i < 16; i++)
        out << "\t" << reg[i];
    out << endl << "X16:";
    for (int i = 16; i < 24; i++)
        out << "\t" << reg[i];
    out << endl << "X24:";
    for (int i = 24; i < 32; i++)
        out << "\t" << reg[i];
    out << endl << endl;
}

// Display data memory
void printData(const vector<string>& data, const int initPC, ofstream& out) {
    out << "Data";
    for (int i = 0; i < data.size(); i++) {
        if (i % 8 == 0)
            out << endl << initPC + i * 4 << ":";
        out << "\t" << convert(data[i], true);
    }
    out << endl << endl;
}

int main(int argc, char** argv) {
    // Read input and initialize registers
    vector<string> input = read(argv[1]);
    vector<int> reg(32, 0);
    vector<string> regS(32, string(32, '0'));

    // Initialize data memory
    vector<string> dataMem, origData;
    int dataIndex = 1;
    for (auto & line : input) {
        if (line.substr(0, 3) == "101")
            break;
        dataIndex++;
    }
    for (int i = dataIndex; i < input.size(); i++) {
        dataMem.push_back(input[i]);
    }
    origData = dataMem;

    // Decode instructions into file
    ofstream sim("simulation.txt");
    int cycle = 1;
    vector<string> instructions(dataIndex, "");
    for (int i = 0; i < dataIndex; i++) {
        sim << string(20, '-') << endl;
        sim << "Cycle " << cycle << ":\t" << (64 + 4 * i) << "\t";
        // Determine instr
        string line = input[i];
        int category = stoi(line.substr(0, 3), nullptr, 2);
        int instr;
        string instrString;
        switch (category) {
            case 1: {
                instr = stoi(line.substr(4, 4), nullptr, 2);
                int src1 = stoi(line.substr(8, 5), nullptr, 2);
                string offsetString(line.substr(13));
                int branchOffset = convert(offsetString, true);
                switch (instr) {
                    case 0:
                        instrString += "CBZ";
                        if (reg[src1] == 0) {
                            i += branchOffset - 1;
                        }
                        break;
                    case 1:
                        instrString += "CBNZ";
                        if (reg[src1] != 0) {
                            i += branchOffset - 1;
                        }
                        break;
                    default:
                        sim << "Bad Category 1 instr" << endl;
                }
                instrString += " X" + (src1 == 31 ? "ZR" : to_string(src1)) + ", #" + to_string(branchOffset);
                break;
            }
            case 2: {
                instr = stoi(line.substr(4, 6), nullptr, 2);
                int dest = stoi(line.substr(10, 5), nullptr, 2);
                int src1 = stoi(line.substr(15, 5), nullptr, 2);
                string immed = line.substr(20);
                int immedVal = 0;
                switch (instr) {
                    case 0: {
                        instrString += "ORRI";
                        immedVal = convert(immed, false);
                        regS[dest] = orop(regS[src1], string(32 - immed.size(), '0') + immed);
                        break;
                    }
                    case 1: {
                        instrString += "EORI";
                        immedVal = convert(immed, false);
                        regS[dest] = xorop(regS[src1], string(32 - immed.size(), '0') + immed);
                        break;
                    }
                    case 2: {
                        instrString += "ADDI";
                        immedVal = convert(immed, true);
                        regS[dest] = to2s(convert(regS[src1], true) + immedVal);
                        break;
                    }
                    case 3: {
                        instrString += "SUBI";
                        immedVal = convert(immed, true);
                        regS[dest] = to2s(convert(regS[src1], true) - immedVal);
                        break;
                    }
                    case 4: {
                        instrString += "ANDI";
                        immedVal = convert(immed, false);
                        regS[dest] = andop(regS[src1], string(32 - immed.size(), '0') + immed);
                        break;
                    }
                    default:
                        sim << "Bad Category 2 instr" << endl;
                }
                if (dest == 31) {
                    regS[dest] = string(32, '0');
                }
                reg[dest] = convert(regS[dest], true);
                instrString += " X" + (dest == 31 ? "ZR" : to_string(dest)) +", X" + (src1 == 31 ? "ZR" : to_string(src1)) + ", #" + to_string(immedVal);
                break;
            }
            case 3: {
                instr = stoi(line.substr(6, 5), nullptr, 2);
                int dest = stoi(line.substr(11, 5), nullptr, 2);
                int src1 = stoi(line.substr(16, 5), nullptr, 2);
                int src2 = stoi(line.substr(21, 5), nullptr, 2);
                switch (instr) {
                    case 0: {
                        instrString += "EOR";
                        regS[dest] = xorop(regS[src1], regS[src2]);
                        break;
                    }
                    case 2: {
                        instrString += "ADD";
                        regS[dest] = to2s(convert(regS[src1], true) + convert(regS[src2], true));
                        break;
                    }
                    case 3: {
                        instrString += "SUB";
                        regS[dest] = to2s(convert(regS[src1], true) - convert(regS[src2], true));
                        break;
                    }
                    case 4: {
                        instrString += "AND";
                        regS[dest] = andop(regS[src1], regS[src2]);
                        break;
                    }
                    case 5: {
                        instrString += "ORR";
                        regS[dest] = orop(regS[src1], regS[src2]);
                        break;
                    }
                    case 6: {
                        instrString += "LSR";
                        int shamt = stoi(regS[src2].substr(27), nullptr, 2);
                        regS[dest] = string(shamt, '0') + regS[src1].substr(0, 32 - shamt);
                        break;
                    }
                    case 7: {
                        instrString += "LSL";
                        int shamt = stoi(regS[src2].substr(27), nullptr, 2);
                        regS[dest] = regS[src1].substr( shamt) + string(shamt, '0');
                        break;
                    }
                    default:
                        sim << "Bad Category 3 instr" << endl;
                }
                if (dest == 31) {
                    regS[dest] = string(32, '0');
                }
                reg[dest] = convert(regS[dest], true);
                instrString += " X" + (dest == 31 ? "ZR" : to_string(dest)) + ", X" + (src1 == 31 ? "ZR" : to_string(src1)) + ", X" + (src2 == 31 ? "ZR" : to_string(src2));
                break;
            }
            case 4: {
                instr = stoi(line.substr(10, 1), nullptr, 2);
                int srcdest = stoi(line.substr(11, 5), nullptr, 2);
                int src1 = stoi(line.substr(16, 5), nullptr, 2);
                string immed = line.substr(21);
                // Calculate values of shift and locations
                int shift = convert(immed, true);
                int start = src1 == 31 ? 0 : convert(regS[src1], true);
                int index = ((start + shift) - 64 - dataIndex * 4) / 4;
                switch (instr) {
                    case 0: {
                        instrString += "LDUR";
                        regS[srcdest] = dataMem[index];
                        if (srcdest == 31) {
                            regS[srcdest] = string(32, '0');
                        }
                        reg[srcdest] = convert(regS[srcdest], true);
                        break;
                    }
                    case 1: {
                        instrString += "STUR";
                        dataMem[index] = regS[srcdest];
                        break;
                    }
                    default:
                        sim << "Bad Category 4 instr" << endl;
                }
                instrString += " X" + (srcdest == 31 ? "ZR" : to_string(srcdest)) + ", [X" + (src1 == 31 ? "ZR" : to_string(src1)) + ", #" + to_string(shift) + "]";
                break;
            }
            default: // Dummy
                instrString += "DUMMY";
        }
        if (instructions[i].empty())
            instructions[i] = instrString;

        // Display cycle info
        sim << instrString << endl << endl;
        printReg(reg, sim);
        printData(dataMem, 64 + dataIndex * 4, sim);
        cycle++;
    }
    sim.close();

    // Print disassembly into file
    ofstream dsam("disassembly.txt");
    int pc = 64;
    for (int i = 0; i < instructions.size(); i++) {
        dsam << input[i] << "\t" << pc << "\t" << instructions[i] << endl;
        pc += 4;
    }
    for (int i = 0; i < dataMem.size(); i++) {
        dsam << input[i + dataIndex] << "\t" << pc << "\t" << convert(origData[i], true) << endl;
        pc += 4;
    }
    dsam.close();

    return 0;
}
