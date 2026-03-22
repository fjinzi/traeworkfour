package com.seckill.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.seckill.dto.UserInfoDTO;
import com.seckill.dto.UserLoginDTO;
import com.seckill.dto.UserRegisterDTO;
import com.seckill.entity.User;
import com.seckill.mapper.UserMapper;
import com.seckill.service.UserService;
import com.seckill.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JwtUtil jwtUtil;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Override
    public UserInfoDTO register(UserRegisterDTO dto) {
        if (checkUsernameExists(dto.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }

        User user = new User();
        user.setUsername(dto.getUsername());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setNickname(dto.getNickname() != null ? dto.getNickname() : dto.getUsername());
        user.setEmail(dto.getEmail());
        user.setPhone(dto.getPhone());
        user.setRoleType(0);
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());
        user.setIsDeleted(0);

        userMapper.insert(user);

        String token = jwtUtil.generateToken(user.getId(), user.getUsername(), user.getRoleType());

        return buildUserInfoDTO(user, token);
    }

    @Override
    public UserInfoDTO login(UserLoginDTO dto) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, dto.getUsername());
        queryWrapper.eq(User::getIsDeleted, 0);

        User user = userMapper.selectOne(queryWrapper);

        if (user == null) {
            throw new RuntimeException("用户不存在");
        }

        if (!passwordEncoder.matches(dto.getPassword(), user.getPassword())) {
            throw new RuntimeException("密码错误");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getUsername(), user.getRoleType());

        return buildUserInfoDTO(user, token);
    }

    @Override
    public UserInfoDTO getUserInfo(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null || user.getIsDeleted() == 1) {
            return null;
        }
        return buildUserInfoDTO(user, null);
    }

    @Override
    public boolean checkUsernameExists(String username) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, username);
        queryWrapper.eq(User::getIsDeleted, 0);
        return userMapper.selectCount(queryWrapper) > 0;
    }

    private UserInfoDTO buildUserInfoDTO(User user, String token) {
        UserInfoDTO dto = new UserInfoDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setNickname(user.getNickname());
        dto.setEmail(user.getEmail());
        dto.setPhone(user.getPhone());
        dto.setRoleType(user.getRoleType());
        dto.setToken(token);
        return dto;
    }
}
